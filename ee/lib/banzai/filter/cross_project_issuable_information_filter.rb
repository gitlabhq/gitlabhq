module Banzai
  module Filter
    # HTML filter that removes sensitive information from cross project
    # issue references.
    #
    # The link to the issue or merge request is preserved only the IID is shown,
    # but all other info is removed.
    class CrossProjectIssuableInformationFilter < HTML::Pipeline::Filter
      def call
        return doc if can_read_cross_project?

        extractor = Banzai::IssuableExtractor.new(project, current_user)
        issuables = extractor.extract([doc])

        issuables.each do |node, issuable|
          next if issuable.project == project

          node['class'] = node['class'].gsub('has-tooltip', '')
          node['title'] = nil
        end

        doc
      end

      private

      def project
        context[:project]
      end

      def can_read_cross_project?
        Ability.allowed?(current_user, :read_cross_project)
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
