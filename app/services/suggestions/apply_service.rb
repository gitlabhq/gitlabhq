# frozen_string_literal: true

module Suggestions
  class ApplyService < ::BaseService
    DEFAULT_SUGGESTION_COMMIT_MESSAGE = 'Apply suggestion to %{file_path}'

    PLACEHOLDERS = {
      'project_path' => ->(suggestion, user) { suggestion.project.path },
      'project_name' => ->(suggestion, user) { suggestion.project.name },
      'file_path' => ->(suggestion, user) { suggestion.file_path },
      'branch_name' => ->(suggestion, user) { suggestion.branch },
      'username' => ->(suggestion, user) { user.username },
      'user_full_name' => ->(suggestion, user) { user.name }
    }.freeze

    # This regex is built dynamically using the keys from the PLACEHOLDER struct.
    # So, we can easily add new placeholder just by modifying the PLACEHOLDER hash.
    # This regex will build the new PLACEHOLDER_REGEX with the new information
    PLACEHOLDERS_REGEX = Regexp.union(PLACEHOLDERS.keys.map { |key| Regexp.new(Regexp.escape(key)) }).freeze

    attr_reader :current_user

    def initialize(current_user)
      @current_user = current_user
    end

    def execute(suggestion)
      unless suggestion.appliable?(cached: false)
        return error('Suggestion is not appliable')
      end

      unless latest_source_head?(suggestion)
        return error('The file has been changed')
      end

      diff_file = suggestion.diff_file

      unless diff_file
        return error('The file was not found')
      end

      params = file_update_params(suggestion, diff_file)
      result = ::Files::UpdateService.new(suggestion.project, current_user, params).execute

      if result[:status] == :success
        suggestion.update(commit_id: result[:result], applied: true)
      end

      result
    rescue Files::UpdateService::FileChangedError
      error('The file has been changed')
    end

    private

    # Checks whether the latest source branch HEAD matches with
    # the position HEAD we're using to update the file content. Since
    # the persisted HEAD is updated async (for MergeRequest),
    # it's more consistent to fetch this data directly from the
    # repository.
    def latest_source_head?(suggestion)
      suggestion.position.head_sha == suggestion.noteable.source_branch_sha
    end

    def file_update_params(suggestion, diff_file)
      blob = diff_file.new_blob
      project = suggestion.project
      file_path = suggestion.file_path
      branch_name = suggestion.branch
      file_content = new_file_content(suggestion, blob)
      commit_message = processed_suggestion_commit_message(suggestion)

      file_last_commit =
        Gitlab::Git::Commit.last_for_path(project.repository,
                                          blob.commit_id,
                                          blob.path)

      {
        file_path: file_path,
        branch_name: branch_name,
        start_branch: branch_name,
        commit_message: commit_message,
        file_content: file_content,
        last_commit_sha: file_last_commit&.id
      }
    end

    def new_file_content(suggestion, blob)
      range = suggestion.from_line_index..suggestion.to_line_index

      blob.load_all_data!
      content = blob.data.lines
      content[range] = suggestion.to_content

      content.join
    end

    def suggestion_commit_message(project)
      project.suggestion_commit_message || DEFAULT_SUGGESTION_COMMIT_MESSAGE
    end

    def processed_suggestion_commit_message(suggestion)
      message = suggestion_commit_message(suggestion.project)

      Gitlab::StringPlaceholderReplacer.replace_string_placeholders(message, PLACEHOLDERS_REGEX) do |key|
        PLACEHOLDERS[key].call(suggestion, current_user)
      end
    end
  end
end
