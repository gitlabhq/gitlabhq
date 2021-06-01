# frozen_string_literal: true

module Banzai
  module Filter
    # HTML Filter for footnotes
    #
    # Footnotes are supported in CommonMark.  However we were stripping
    # the ids during sanitization.  Those are now allowed.
    #
    # Footnotes are numbered the same - the first one has `id=fn1`, the
    # second is `id=fn2`, etc.  In order to allow footnotes when rendering
    # multiple markdown blocks on a page, we need to make each footnote
    # reference unique.
    #
    # This filter adds a random number to each footnote (the same number
    # can be used for a single render). So you get `id=fn1-4335` and `id=fn2-4335`.
    #
    class FootnoteFilter < HTML::Pipeline::Filter
      INTEGER_PATTERN                 = /\A\d+\z/.freeze
      FOOTNOTE_ID_PREFIX              = 'fn'
      FOOTNOTE_LINK_ID_PREFIX         = 'fnref'
      FOOTNOTE_LI_REFERENCE_PATTERN   = /\A#{FOOTNOTE_ID_PREFIX}\d+\z/.freeze
      FOOTNOTE_LINK_REFERENCE_PATTERN = /\A#{FOOTNOTE_LINK_ID_PREFIX}\d+\z/.freeze
      FOOTNOTE_START_NUMBER           = 1

      CSS_SECTION    = "ol > li[id=#{FOOTNOTE_ID_PREFIX}#{FOOTNOTE_START_NUMBER}]"
      XPATH_SECTION  = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_SECTION).freeze
      CSS_FOOTNOTE   = 'sup > a[id]'
      XPATH_FOOTNOTE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_FOOTNOTE).freeze

      def call
        return doc unless first_footnote = doc.at_xpath(XPATH_SECTION)

        # Sanitization stripped off the section wrapper - add it back in
        first_footnote.parent.wrap('<section class="footnotes">')
        rand_suffix = "-#{random_number}"
        modified_footnotes = {}

        doc.xpath(XPATH_FOOTNOTE).each do |link_node|
          ref_num       = link_node[:id].delete_prefix(FOOTNOTE_LINK_ID_PREFIX)
          node_xpath    = Gitlab::Utils::Nokogiri.css_to_xpath("li[id=#{fn_id(ref_num)}]")
          footnote_node = doc.at_xpath(node_xpath)

          if INTEGER_PATTERN.match?(ref_num) && (footnote_node || modified_footnotes[ref_num])
            link_node[:href] += rand_suffix
            link_node[:id]   += rand_suffix

            # Sanitization stripped off class - add it back in
            link_node.parent.append_class('footnote-ref')

            unless modified_footnotes[ref_num]
              footnote_node[:id] += rand_suffix
              backref_node        = footnote_node.at_css("a[href=\"##{fnref_id(ref_num)}\"]")

              if backref_node
                backref_node[:href] += rand_suffix
                backref_node.append_class('footnote-backref')
              end

              modified_footnotes[ref_num] = true
            end
          end
        end

        doc
      end

      private

      def random_number
        @random_number ||= rand(10000)
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
