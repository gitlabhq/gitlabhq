# frozen_string_literal: true

module Suggestions
  class ApplyService < ::BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(suggestion)
      unless suggestion.appliable?
        return error('Suggestion is not appliable')
      end

      params = file_update_params(suggestion)
      result = ::Files::UpdateService.new(suggestion.project, @current_user, params).execute

      if result[:status] == :success
        suggestion.update(commit_id: result[:result], applied: true)
      end

      result
    end

    private

    def file_update_params(suggestion)
      diff_file = suggestion.diff_file

      file_path = diff_file.file_path
      branch_name = suggestion.noteable.source_branch
      file_content = new_file_content(suggestion)
      commit_message = "Apply suggestion to #{file_path}"

      {
        file_path: file_path,
        branch_name: branch_name,
        start_branch: branch_name,
        commit_message: commit_message,
        file_content: file_content
      }
    end

    def new_file_content(suggestion)
      range = suggestion.from_line_index..suggestion.to_line_index
      blob = suggestion.diff_file.new_blob

      blob.load_all_data!
      content = blob.data.lines
      content[range] = suggestion.to_content

      content.join
    end
  end
end
