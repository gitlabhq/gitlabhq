# frozen_string_literal: true

module Gitlab
  module Suggestions
    class CommitMessage
      DEFAULT_SUGGESTION_COMMIT_MESSAGE =
        "Apply %{suggestions_count} suggestion(s) to %{files_count} file(s)\n\n%{co_authored_by}"

      def initialize(user, suggestion_set, custom_message = nil)
        @user = user
        @suggestion_set = suggestion_set
        @custom_message = custom_message
      end

      def message
        project = suggestion_set.target_project
        user_defined_message = @custom_message.presence || project.suggestion_commit_message.presence
        message = user_defined_message || DEFAULT_SUGGESTION_COMMIT_MESSAGE

        Gitlab::StringPlaceholderReplacer
          .replace_string_placeholders(message, PLACEHOLDERS_REGEX) do |key|
          PLACEHOLDERS[key].call(user, suggestion_set)
        end
      end

      def self.format_paths(paths)
        paths.sort.join(', ')
      end

      private_class_method :format_paths

      private

      attr_reader :user, :suggestion_set

      PLACEHOLDERS = {
        'branch_name' => ->(user, suggestion_set) { suggestion_set.branch },
        'files_count' => ->(user, suggestion_set) { suggestion_set.file_paths.length },
        'file_paths' => ->(user, suggestion_set) { format_paths(suggestion_set.file_paths) },
        'project_name' => ->(user, suggestion_set) { suggestion_set.target_project.name },
        'project_path' => ->(user, suggestion_set) { suggestion_set.target_project.path },
        'user_full_name' => ->(user, suggestion_set) { user.name },
        'username' => ->(user, suggestion_set) { user.username },
        'suggestions_count' => ->(user, suggestion_set) { suggestion_set.suggestions.size },
        'co_authored_by' => ->(user, suggestions_set) {
          suggestions_set.authors.without(user).map do |author|
            "#{Commit::CO_AUTHORED_TRAILER}: #{author.name} <#{author.commit_email_or_default}>"
          end.join("\n")
        }
      }.freeze

      # This regex is built dynamically using the keys from the PLACEHOLDER struct.
      # So, we can easily add new placeholder just by modifying the PLACEHOLDER hash.
      # This regex will build the new PLACEHOLDER_REGEX with the new information
      PLACEHOLDERS_REGEX = Regexp.union(PLACEHOLDERS.keys.map do |key|
        Regexp.new(Regexp.escape(key))
      end).freeze
    end
  end
end
