module Gitlab
  module Markdown
    # Includes shared code for reference filters that support an optional
    # cross-project reference.
    module CrossProjectReference
      NAMING_PATTERN  = Gitlab::Regex::NAMESPACE_REGEX_STR
      PROJECT_PATTERN = "(?<project>#{NAMING_PATTERN}/#{NAMING_PATTERN})"

      # Given a cross-project reference string, get the Project record
      #
      # If no valid reference is given, returns the `:project` value for the
      # current context.
      #
      # ref - String reference.
      #
      # Returns a Project
      def project_from_ref(ref)
        if ref && other = Project.find_with_namespace(ref)
          other
        else
          context[:project]
        end
      end
    end
  end
end
