# frozen_string_literal: true

module Banzai
  module Filter
    # HTML Filter for footnotes
    #
    # Footnotes are supported in CommonMark.  However we were stripping
    # the ids during sanitization.  Those are now allowed.
    #
    # Footnotes are numbered as an increasing integer starting at `1`.
    # The `id` associated with a footnote is based on the footnote reference
    # string.  For example, `[^foot]` will generate `id="fn-foot"`.
    # In order to allow footnotes when rendering multiple markdown blocks
    # on a page, we need to make each footnote reference unique.

    # This filter adds a random number to each footnote (the same number
    # can be used for a single render). So you get `id=fn-1-4335` and `id=fn-foot-4335`.
    #
    class FootnoteFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      FOOTNOTE_ID_PREFIX              = 'fn-'
      FOOTNOTE_LINK_ID_PREFIX         = 'fnref-'
      FOOTNOTE_LI_REFERENCE_PATTERN   = /\A#{FOOTNOTE_ID_PREFIX}.+\z/
      FOOTNOTE_LINK_REFERENCE_PATTERN = /\A#{FOOTNOTE_LINK_ID_PREFIX}.+\z/

      CSS_SECTION    = "section[data-footnotes]"
      XPATH_SECTION  = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_SECTION).freeze
      CSS_FOOTNOTE   = 'sup > a[data-footnote-ref]'
      XPATH_FOOTNOTE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_FOOTNOTE).freeze

      # Limit of how many footnotes we will process.
      # Protects against pathological number of footnotes.
      FOOTNOTE_LIMIT = 1000

      def call
        # Sanitization stripped off the section class - add it back in
        return doc if doc.xpath(XPATH_FOOTNOTE).count > 1000
        return doc unless section_node = doc.at_xpath(XPATH_SECTION)

        section_node.append_class('footnotes')

        rand_suffix = "-#{random_number}"
        modified_footnotes = {}

        doc.xpath(XPATH_FOOTNOTE).each do |link_node|
          next unless link_node[:id]

          ref_num = link_node[:id].delete_prefix(FOOTNOTE_LINK_ID_PREFIX)
          ref_num.gsub!(/[[:punct:]]/, '\\\\\&')

          css = "section[data-footnotes] li[id=#{fn_id(ref_num)}]"
          node_xpath = Gitlab::Utils::Nokogiri.css_to_xpath(css)
          footnote_node = doc.at_xpath(node_xpath)

          next unless footnote_node || modified_footnotes[ref_num]

          link_node[:href] += rand_suffix
          link_node[:id]   += rand_suffix

          # Sanitization stripped off class - add it back in
          link_node.parent.append_class('footnote-ref')

          next if modified_footnotes[ref_num]

          footnote_node[:id] += rand_suffix
          backref_node        = footnote_node.at_css("a[href=\"##{fnref_id(ref_num)}\"]")

          if backref_node
            backref_node[:href] += rand_suffix

            footnote_id = backref_node['data-footnote-backref-idx']
            backref_node[:title] = format(_("Back to reference %{footnote_id}"), footnote_id: footnote_id)
            backref_node['aria-label'] = backref_node[:title]
            backref_node.append_class('footnote-backref')
          end

          modified_footnotes[ref_num] = true
        end

        doc
      end

      private

      def random_number
        # We allow overriding the randomness with a static value from GITLAB_TEST_FOOTNOTE_ID.
        # This allows stable generation of example HTML during GLFM Snapshot Testing
        # (https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing),
        # and reduces the need for normalization of the example HTML
        # (https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#normalization)
        @random_number ||= ENV.fetch('GITLAB_TEST_FOOTNOTE_ID', rand(10000))
      end

      def fn_id(num)
        "#{FOOTNOTE_ID_PREFIX}#{num}"
      end

      def fnref_id(num)
        "#{FOOTNOTE_LINK_ID_PREFIX}#{num}"
      end
    end
  end
end
