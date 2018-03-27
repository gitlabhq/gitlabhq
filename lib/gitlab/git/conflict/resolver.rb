module Gitlab
  module Git
    module Conflict
      class Resolver
        ConflictSideMissing = Class.new(StandardError)
        ResolutionError = Class.new(StandardError)

        def initialize(target_repository, our_commit_oid, their_commit_oid)
          @target_repository = target_repository
          @our_commit_oid = our_commit_oid
          @their_commit_oid = their_commit_oid
        end

        def conflicts
          @conflicts ||= begin
            @target_repository.gitaly_migrate(:conflicts_list_conflict_files) do |is_enabled|
              if is_enabled
                gitaly_conflicts_client(@target_repository).list_conflict_files.to_a
              else
                rugged_list_conflict_files
              end
            end
          end
        rescue GRPC::FailedPrecondition => e
          raise Gitlab::Git::Conflict::Resolver::ConflictSideMissing.new(e.message)
        rescue Rugged::OdbError, GRPC::BadStatus => e
          raise Gitlab::Git::CommandError.new(e)
        end

        def resolve_conflicts(source_repository, resolution, source_branch:, target_branch:)
          source_repository.gitaly_migrate(:conflicts_resolve_conflicts) do |is_enabled|
            if is_enabled
              gitaly_conflicts_client(source_repository).resolve_conflicts(@target_repository, resolution, source_branch, target_branch)
            else
              rugged_resolve_conflicts(source_repository, resolution, source_branch, target_branch)
            end
          end
        end

        def conflict_for_path(conflicts, old_path, new_path)
          conflicts.find do |conflict|
            conflict.their_path == old_path && conflict.our_path == new_path
          end
        end

        private

        def conflict_files(repository, index)
          index.conflicts.map do |conflict|
            raise ConflictSideMissing unless conflict[:theirs] && conflict[:ours]

            Gitlab::Git::Conflict::File.new(
              repository,
              @our_commit_oid,
              conflict,
              index.merge_file(conflict[:ours][:path])[:data]
            )
          end
        end

        def gitaly_conflicts_client(repository)
          repository.gitaly_conflicts_client(@our_commit_oid, @their_commit_oid)
        end

        def write_resolved_file_to_index(repository, index, file, params)
          if params[:sections]
            resolved_lines = file.resolve_lines(params[:sections])
            new_file = resolved_lines.map { |line| line[:full_line] }.join("\n")

            new_file << "\n" if file.our_blob.data.end_with?("\n")
          elsif params[:content]
            new_file = file.resolve_content(params[:content])
          end

          our_path = file.our_path

          oid = repository.rugged.write(new_file, :blob)
          index.add(path: our_path, oid: oid, mode: file.our_mode)
          index.conflict_remove(our_path)
        end

        def rugged_list_conflict_files
          target_index = @target_repository.rugged.merge_commits(@our_commit_oid, @their_commit_oid)

          # We don't need to do `with_repo_branch_commit` here, because the target
          # project always fetches source refs when creating merge request diffs.
          conflict_files(@target_repository, target_index)
        end

        def rugged_resolve_conflicts(source_repository, resolution, source_branch, target_branch)
          source_repository.with_repo_branch_commit(@target_repository, target_branch) do
            index = source_repository.rugged.merge_commits(@our_commit_oid, @their_commit_oid)
            conflicts = conflict_files(source_repository, index)

            resolution.files.each do |file_params|
              conflict_file = conflict_for_path(conflicts, file_params[:old_path], file_params[:new_path])

              write_resolved_file_to_index(source_repository, index, conflict_file, file_params)
            end

            unless index.conflicts.empty?
              missing_files = index.conflicts.map { |file| file[:ours][:path] }

              raise ResolutionError, "Missing resolutions for the following files: #{missing_files.join(', ')}"
            end

            commit_params = {
              message: resolution.commit_message,
              parents: [@our_commit_oid, @their_commit_oid]
            }

            source_repository.commit_index(resolution.user, source_branch, index, commit_params)
          end
        end
      end
    end
  end
end
