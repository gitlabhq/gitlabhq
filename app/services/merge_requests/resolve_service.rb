module MergeRequests
  class ResolveService < MergeRequests::BaseService
    attr_accessor :conflicts, :rugged, :merge_index

    def execute(merge_request)
      @conflicts = merge_request.conflicts
      @rugged = project.repository.rugged
      @merge_index = conflicts.merge_index

      conflicts.files.each do |file|
        write_resolved_file_to_index(file, params[:sections])
      end

      commit_params = {
        message: params[:commit_message] || conflicts.default_commit_message,
        parents: [conflicts.our_commit, conflicts.their_commit].map(&:oid),
        tree: merge_index.write_tree(rugged)
      }

      project.repository.resolve_conflicts(current_user, merge_request.source_branch, commit_params)
    end

    def write_resolved_file_to_index(file, resolutions)
      new_file = file.resolve_lines(resolutions).map(&:text).join("\n")
      our_path = file.our_path

      merge_index.add(path: our_path, oid: rugged.write(new_file, :blob), mode: file.our_mode)
      merge_index.conflict_remove(our_path)
    end
  end
end
