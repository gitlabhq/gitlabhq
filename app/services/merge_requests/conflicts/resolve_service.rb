module MergeRequests
  module Conflicts
    class ResolveService < MergeRequests::Conflicts::BaseService
      MissingFiles = Class.new(Gitlab::Conflict::ResolutionError)

      def execute(current_user, params)
        rugged = merge_request.source_project.repository.rugged

        Gitlab::Conflict::FileCollection.for_resolution(merge_request) do |conflicts_for_resolution|
          merge_index = conflicts_for_resolution.merge_index

          params[:files].each do |file_params|
            conflict_file = conflicts_for_resolution.file_for_path(file_params[:old_path], file_params[:new_path])

            write_resolved_file_to_index(merge_index, rugged, conflict_file, file_params)
          end

          unless merge_index.conflicts.empty?
            missing_files = merge_index.conflicts.map { |file| file[:ours][:path] }

            raise MissingFiles, "Missing resolutions for the following files: #{missing_files.join(', ')}"
          end

          commit_params = {
            message: params[:commit_message] || conflicts_for_resolution.default_commit_message,
            parents: [conflicts_for_resolution.our_commit, conflicts_for_resolution.their_commit].map(&:oid),
            tree: merge_index.write_tree(rugged)
          }

          conflicts_for_resolution.
            project.
            repository.
            resolve_conflicts(current_user, merge_request.source_branch, commit_params)
        end
      end

      private

      def write_resolved_file_to_index(merge_index, rugged, file, params)
        new_file = if params[:sections]
                     file.resolve_lines(params[:sections]).map(&:text).join("\n")
                   elsif params[:content]
                     file.resolve_content(params[:content])
                   end

        our_path = file.our_path

        merge_index.add(path: our_path, oid: rugged.write(new_file, :blob), mode: file.our_mode)
        merge_index.conflict_remove(our_path)
      end
    end
  end
end
