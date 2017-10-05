module Gitlab
  module Conflict
    class FileCollection
      ConflictSideMissing = Class.new(StandardError)
      MissingFiles = Class.new(ResolutionError)

      attr_reader :merge_request, :our_commit, :their_commit, :project, :read_only

      delegate :repository, to: :project

      class << self
        # We can only write when getting the merge index from the source
        # project, because we will write to that project. We don't use this all
        # the time because this fetches a ref into the source project, which
        # isn't needed for reading.
        def for_resolution(merge_request)
          new(merge_request, merge_request.source_project, false)
        end

        # We don't need to do `with_repo_branch_commit` here, because the target
        # project always fetches source refs when creating merge request diffs.
        def read_only(merge_request)
          new(merge_request, merge_request.target_project, true)
        end
      end

      def resolve(user, commit_message, files)
        raise "can't resolve a read-only Conflict File Collection" if read_only

        repository.with_repo_branch_commit(merge_request.target_project.repository.raw, merge_request.target_branch) do
          rugged = repository.rugged

          files.each do |file_params|
            conflict_file = file_for_path(file_params[:old_path], file_params[:new_path])

            write_resolved_file_to_index(merge_index, rugged, conflict_file, file_params)
          end

          unless merge_index.conflicts.empty?
            missing_files = merge_index.conflicts.map { |file| file[:ours][:path] }

            raise MissingFiles, "Missing resolutions for the following files: #{missing_files.join(', ')}"
          end

          commit_params = {
            message: commit_message || default_commit_message,
            parents: [our_commit, their_commit].map(&:oid),
            tree: merge_index.write_tree(rugged)
          }

          repository.resolve_conflicts(user, merge_request.source_branch, commit_params)
        end
      end

      def merge_index
        @merge_index ||= repository.rugged.merge_commits(our_commit, their_commit)
      end

      def files
        @files ||= merge_index.conflicts.map do |conflict|
          raise ConflictSideMissing unless conflict[:theirs] && conflict[:ours]

          Gitlab::Conflict::File.new(merge_index.merge_file(conflict[:ours][:path]),
                                     conflict,
                                     merge_request: merge_request)
        end
      end

      def file_for_path(old_path, new_path)
        files.find { |file| file.their_path == old_path && file.our_path == new_path }
      end

      def as_json(opts = nil)
        {
          target_branch: merge_request.target_branch,
          source_branch: merge_request.source_branch,
          commit_sha: merge_request.diff_head_sha,
          commit_message: default_commit_message,
          files: files
        }
      end

      def default_commit_message
        conflict_filenames = merge_index.conflicts.map do |conflict|
          "#   #{conflict[:ours][:path]}"
        end

        <<EOM.chomp
Merge branch '#{merge_request.target_branch}' into '#{merge_request.source_branch}'

# Conflicts:
#{conflict_filenames.join("\n")}
EOM
      end

      private

      def write_resolved_file_to_index(merge_index, rugged, file, params)
        if params[:sections]
          new_file = file.resolve_lines(params[:sections]).map(&:text).join("\n")

          new_file << "\n" if file.our_blob.data.ends_with?("\n")
        elsif params[:content]
          new_file = file.resolve_content(params[:content])
        end

        our_path = file.our_path

        merge_index.add(path: our_path, oid: rugged.write(new_file, :blob), mode: file.our_mode)
        merge_index.conflict_remove(our_path)
      end

      def initialize(merge_request, project, read_only)
        @merge_request = merge_request
        @our_commit = merge_request.source_branch_head.raw.rugged_commit
        @their_commit = merge_request.target_branch_head.raw.rugged_commit
        @project = project
        @read_only = read_only
      end
    end
  end
end
