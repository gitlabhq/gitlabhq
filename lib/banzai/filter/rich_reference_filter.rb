module Banzai
  module Filter
    # HTML filter to support rich references in links.
    #
    # Appends information on the link text depending on the verbosity
    # level. It is expected to run in a post-processing pipeline.
    class RichReferenceFilter < HTML::Pipeline::Filter
      VERBOSITY_CHAR = '+'

      def call
        links.each do |link|
          handle_reference_verbosity_for(link)
        end
        doc
      end

      private

      def links
        @links ||= doc.css('a[data-rich-ref-verbosity]')
      end

      def handle_reference_verbosity_for(link)
        verbosity = link.attr('data-rich-ref-verbosity').to_i
        if verbosity > 0
          link.content = "#{link.text} #{link.attr('title')}"
        end

        if verbosity > 1
          # We support up to 3 levels of verbosity, but for now we implement
          # only 1. Restore the missing '+' characters.
          # This will not be needed if we support verbosity up to 3.
          missing = VERBOSITY_CHAR * (verbosity - 1)
          link.add_next_sibling(missing)
        end
      end
    end
  end
end
