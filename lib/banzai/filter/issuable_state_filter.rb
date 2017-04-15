module Banzai
  module Filter
    # HTML filter that appends state information to issuable links.
    # Runs as a post-process filter as issuable state might change whilst
    # Markdown is in the cache.
    #
    # This filter supports cross-project references.
    class IssuableStateFilter < HTML::Pipeline::Filter
      VISIBLE_STATES = %w(closed merged).freeze

      def call
        extractor = Banzai::IssuableExtractor.new(project, current_user)
        issuables = extractor.extract([doc])

        issuables.each do |node, issuable|
          if VISIBLE_STATES.include?(issuable.state) && node.children.present?
            node.add_child(Nokogiri::XML::Text.new(" [#{issuable.state}]", doc))
          end
        end

        doc
      end

      private

      def current_user
        context[:current_user]
      end

      def project
        context[:project]
      end
    end
  end
end
