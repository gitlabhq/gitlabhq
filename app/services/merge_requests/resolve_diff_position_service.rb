# frozen_string_literal: true

module MergeRequests
  class ResolveDiffPositionService < ::BaseService
    def execute
      merge_request = params[:merge_request]
      file_path = params[:file_path]
      new_line = params[:new_line]
      old_line = params[:old_line]
      head_sha = params[:head_sha]

      diff_refs = merge_request.diff_refs
      unless diff_refs&.complete?
        return ServiceResponse.error(message: 'Could not determine diff refs for this merge request')
      end

      if diff_refs.head_sha != head_sha
        return ServiceResponse.error(
          message: 'The provided head_sha does not match the current merge request diff. ' \
            'The diff may have been updated since you last viewed it.'
        )
      end

      diff_file = find_diff_file(merge_request, file_path)
      return ServiceResponse.error(message: "File not found in merge request diff: #{file_path}") unless diff_file

      position_attrs = {
        old_path: diff_file.old_path,
        new_path: diff_file.new_path,
        base_sha: diff_refs.base_sha,
        start_sha: diff_refs.start_sha,
        head_sha: diff_refs.head_sha,
        position_type: 'text'
      }

      position_attrs[:new_line] = new_line if new_line
      position_attrs[:old_line] = old_line if old_line

      ServiceResponse.success(payload: { position: position_attrs })
    end

    private

    def find_diff_file(merge_request, file_path)
      merge_request_diff = merge_request.merge_request_diff
      return unless merge_request_diff

      merge_request_diff.merge_request_diff_files.by_paths([file_path]).first
    end
  end
end
