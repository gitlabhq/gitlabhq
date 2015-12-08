require 'gitlab/markdown'

module Gitlab
  module Markdown
    # Common methods for ReferenceFilters that support an optional cross-project
    # reference.
    module CrossProjectReference
      # Given a cross-project reference string, get the Project record
      #
      # Defaults to value of `context[:project]` if:
      # * No reference is given OR
      # * Reference given doesn't exist
      #
      # ref - String reference.
      #
      # Returns a Project, or nil if the reference can't be found
      def project_from_ref(ref)
        return context[:project] unless ref

        Project.find_with_namespace(ref)
      end
    end
  end
end
