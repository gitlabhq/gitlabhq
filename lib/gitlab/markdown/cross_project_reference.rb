module Gitlab
  module Markdown
    # Common methods for ReferenceFilters that support an optional cross-project
    # reference.
    module CrossProjectReference
      NAMING_PATTERN  = Gitlab::Regex::NAMESPACE_REGEX_STR
      PROJECT_PATTERN = "(?<project>#{NAMING_PATTERN}/#{NAMING_PATTERN})"

      # Given a cross-project reference string, get the Project record
      #
      # Defaults to value of `context[:project]` if:
      # * No reference is given OR
      # * Reference given doesn't exist
      #
      # ref - String reference.
      #
      # Returns a Project, or nil if the reference can't be accessed
      def project_from_ref(ref)
        if ref && other = Project.find_with_namespace(ref)
          if user_can_reference_project?(other)
            other
          else
            nil
          end
        else
          context[:project]
        end
      end

      def user_can_reference_project?(project, user = context[:current_user])
        Ability.abilities.allowed?(user, :read_project, project)
      end
    end
  end
end
