# frozen_string_literal: true

module Suggestions
  class ApplyService < ::BaseService
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
      result = ::Files::UpdateService.new(suggestion.project, @current_user, params).execute

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
      file_path = suggestion.file_path
      branch_name = suggestion.branch
      file_content = new_file_content(suggestion, blob)
      commit_message = "Apply suggestion to #{file_path}"

      file_last_commit =
        Gitlab::Git::Commit.last_for_path(suggestion.project.repository,
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
  end
end
