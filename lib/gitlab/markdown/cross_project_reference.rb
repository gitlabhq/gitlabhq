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
      # * Reference given doesn't exist OR
      # * Reference given can't be read by the current user
      #
      # ref - String reference.
      #
      # Returns a Project
      def project_from_ref(ref)
        if ref && other = Project.find_with_namespace(ref)
          if user_can_reference_project?(other)
            other
          else
            context[:project]
          end
        else
          context[:project]
        end
      end

      def user_can_reference_project?(project, user = context[:current_user])
        user && Ability.abilities.allowed?(user, :read_project, project)
      end
    end
  end
end
