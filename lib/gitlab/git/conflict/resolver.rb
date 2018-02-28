module Gitlab
  module Git
    module Conflict
      class Resolver
        ConflictSideMissing = Class.new(StandardError)
        ResolutionError = Class.new(StandardError)

        def initialize(repository, our_commit, target_repository, their_commit)
          @repository = repository
          @our_commit = our_commit.rugged_commit
          @target_repository = target_repository
          @their_commit = their_commit.rugged_commit
        end

        def conflicts
          @conflicts ||= begin
            target_index = @target_repository.rugged.merge_commits(@our_commit, @their_commit)

            # We don't need to do `with_repo_branch_commit` here, because the target
            # project always fetches source refs when creating merge request diffs.
            target_index.conflicts.map do |conflict|
              raise ConflictSideMissing unless conflict[:theirs] && conflict[:ours]

              Gitlab::Git::Conflict::File.new(
                @target_repository,
                @our_commit.oid,
                conflict,
                target_index.merge_file(conflict[:ours][:path])[:data]
              )
            end
          end
        end

        def resolve_conflicts(user, files, source_branch:, target_branch:, commit_message:)
          @repository.with_repo_branch_commit(@target_repository, target_branch) do
            files.each do |file_params|
              conflict_file = conflict_for_path(file_params[:old_path], file_params[:new_path])

              write_resolved_file_to_index(conflict_file, file_params)
            end

            unless index.conflicts.empty?
              missing_files = index.conflicts.map { |file| file[:ours][:path] }

              raise ResolutionError, "Missing resolutions for the following files: #{missing_files.join(', ')}"
            end

            commit_params = {
              message: commit_message,
              parents: [@our_commit, @their_commit].map(&:oid)
            }

            @repository.commit_index(user, source_branch, index, commit_params)
          end
        end

        def conflict_for_path(old_path, new_path)
          conflicts.find do |conflict|
            conflict.their_path == old_path && conflict.our_path == new_path
          end
        end

        private

        # We can only write when getting the merge index from the source
        # project, because we will write to that project. We don't use this all
        # the time because this fetches a ref into the source project, which
        # isn't needed for reading.
        def index
          @index ||= @repository.rugged.merge_commits(@our_commit, @their_commit)
        end

        def write_resolved_file_to_index(file, params)
          if params[:sections]
            resolved_lines = file.resolve_lines(params[:sections])
            new_file = resolved_lines.map { |line| line[:full_line] }.join("\n")

            new_file << "\n" if file.our_blob.data.ends_with?("\n")
          elsif params[:content]
            new_file = file.resolve_content(params[:content])
          end

          our_path = file.our_path

          index.add(path: our_path, oid: @repository.rugged.write(new_file, :blob), mode: file.our_mode)
          index.conflict_remove(our_path)
        end
      end
    end
  end
end
