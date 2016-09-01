module MergeRequests
  class ResolveService < MergeRequests::BaseService
    class MissingFiles < Gitlab::Conflict::ResolutionError
    end

    attr_accessor :conflicts, :rugged, :merge_index, :merge_request

    def execute(merge_request)
      @conflicts = merge_request.conflicts
      @rugged = project.repository.rugged
      @merge_index = conflicts.merge_index
      @merge_request = merge_request

      fetch_their_commit!

      params[:files].each do |file_params|
        conflict_file = merge_request.conflicts.file_for_path(file_params[:old_path], file_params[:new_path])

        write_resolved_file_to_index(conflict_file, file_params)
      end

      unless merge_index.conflicts.empty?
        missing_files = merge_index.conflicts.map { |file| file[:ours][:path] }

        raise MissingFiles, "Missing resolutions for the following files: #{missing_files.join(', ')}"
      end

      commit_params = {
        message: params[:commit_message] || conflicts.default_commit_message,
        parents: [conflicts.our_commit, conflicts.their_commit].map(&:oid),
        tree: merge_index.write_tree(rugged)
      }

      project.repository.resolve_conflicts(current_user, merge_request.source_branch, commit_params)
    end

    def write_resolved_file_to_index(file, params)
      new_file = if params[:sections]
                   file.resolve_lines(params[:sections]).map(&:text).join("\n")
                 elsif params[:content]
                   file.resolve_content(params[:content])
                 end

      our_path = file.our_path

      merge_index.add(path: our_path, oid: rugged.write(new_file, :blob), mode: file.our_mode)
      merge_index.conflict_remove(our_path)
    end

    # If their commit (in the target project) doesn't exist in the source project, it
    # can't be a parent for the merge commit we're about to create. If that's the case,
    # fetch the target branch ref into the source project so the commit exists in both.
    #
    def fetch_their_commit!
      return if rugged.include?(conflicts.their_commit.oid)

      random_string = SecureRandom.hex

      project.repository.fetch_ref(
        merge_request.target_project.repository.path_to_repo,
        "refs/heads/#{merge_request.target_branch}",
        "refs/tmp/#{random_string}/head"
      )
    end
  end
end
