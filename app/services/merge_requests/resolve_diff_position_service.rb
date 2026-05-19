# frozen_string_literal: true

module MergeRequests
  class ResolveDiffPositionService < ::BaseService
    def execute
      merge_request = params[:merge_request]
      file_path = params[:file_path]
      new_line = params[:new_line]
      old_line = params[:old_line]
      end_new_line = params[:end_new_line]
      end_old_line = params[:end_old_line]
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

      resolved_file_path = diff_file.new_path.presence || diff_file.old_path

      position_attrs = {
        old_path: diff_file.old_path,
        new_path: diff_file.new_path,
        base_sha: diff_refs.base_sha,
        start_sha: diff_refs.start_sha,
        head_sha: diff_refs.head_sha,
        position_type: 'text'
      }

      if end_new_line || end_old_line
        apply_multiline_position!(position_attrs, resolved_file_path,
          old_line: old_line, new_line: new_line,
          end_old_line: end_old_line, end_new_line: end_new_line)
      else
        position_attrs[:new_line] = new_line if new_line
        position_attrs[:old_line] = old_line if old_line
      end

      ServiceResponse.success(payload: { position: position_attrs })
    end

    private

    # For multiline notes, the top-level position line is the end of the range
    # (the anchor), while line_range captures the full start-to-end span.
    def apply_multiline_position!(position_attrs, file_path, old_line:, new_line:, end_old_line:, end_new_line:)
      position_attrs[:new_line] = end_new_line if end_new_line
      position_attrs[:old_line] = end_old_line if end_old_line
      position_attrs[:line_range] = build_line_range(
        file_path,
        old_line: old_line, new_line: new_line,
        end_old_line: end_old_line, end_new_line: end_new_line
      )
    end

    def find_diff_file(merge_request, file_path)
      merge_request_diff = merge_request.merge_request_diff
      return unless merge_request_diff

      merge_request_diff.merge_request_diff_files.by_paths([file_path]).first
    end

    # String keys are required - Gitlab::Diff::Position accesses line_range with string keys
    def build_line_range(file_path, old_line:, new_line:, end_old_line:, end_new_line:)
      {
        'start' => build_line_range_entry(file_path, old_line: old_line, new_line: new_line),
        'end' => build_line_range_entry(file_path, old_line: end_old_line, new_line: end_new_line)
      }
    end

    def build_line_range_entry(file_path, old_line:, new_line:)
      entry = {
        'line_code' => Gitlab::Git.diff_line_code(file_path, new_line || 0, old_line || 0),
        'type' => line_type(old_line: old_line, new_line: new_line)
      }

      entry['old_line'] = old_line if old_line
      entry['new_line'] = new_line if new_line
      entry
    end

    def line_type(old_line:, new_line:)
      if old_line && new_line
        nil
      elsif new_line
        'new'
      else
        'old'
      end
    end
  end
end
