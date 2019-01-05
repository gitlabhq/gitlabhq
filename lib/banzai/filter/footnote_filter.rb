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
      INTEGER_PATTERN = /\A\d+\Z/.freeze

      def call
        return doc unless first_footnote = doc.at_css('ol > li[id=fn1]')

        # Sanitization stripped off the section wrapper - add it back in
        first_footnote.parent.wrap('<section class="footnotes">')

        doc.css('sup > a[id]').each do |link_node|
          ref_num       = link_node[:id].delete_prefix('fnref')
          footnote_node = doc.at_css("li[id=fn#{ref_num}]")
          backref_node  = doc.at_css("li[id=fn#{ref_num}] a[href=\"#fnref#{ref_num}\"]")

          if ref_num =~ INTEGER_PATTERN && footnote_node && backref_node
            rand_ref_num        = "#{ref_num}-#{random_number}"
            link_node[:href]    = "#fn#{rand_ref_num}"
            link_node[:id]      = "fnref#{rand_ref_num}"
            footnote_node[:id]  = "fn#{rand_ref_num}"
            backref_node[:href] = "#fnref#{rand_ref_num}"

            # Sanitization stripped off class - add it back in
            link_node.parent.append_class('footnote-ref')
            backref_node.append_class('footnote-backref')
          end
        end

        doc
      end

      private

      def random_number
        @random_number ||= rand(10000)
      end
    end
  end
end
