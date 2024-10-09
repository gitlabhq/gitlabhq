# frozen_string_literal: true

module Gitlab
  module Git
    module Conflict
      class Resolver
        include Gitlab::Git::WrapsGitalyErrors

        ConflictSideMissing = Class.new(StandardError)
        ResolutionError = Class.new(StandardError)

        def initialize(target_repository, our_commit_oid, their_commit_oid, allow_tree_conflicts: false, skip_content: false)
          @target_repository = target_repository
          @our_commit_oid = our_commit_oid
          @their_commit_oid = their_commit_oid
          @allow_tree_conflicts = allow_tree_conflicts
          @skip_content = skip_content
        end

        def conflicts
          @conflicts ||= wrapped_gitaly_errors do
            gitaly_conflicts_client(@target_repository)
              .list_conflict_files(
                allow_tree_conflicts: @allow_tree_conflicts,
                skip_content: @skip_content
              )
              .to_a
          rescue GRPC::FailedPrecondition => e
            raise Gitlab::Git::Conflict::Resolver::ConflictSideMissing, e.message
          end
        rescue GRPC::BadStatus => e
          raise Gitlab::Git::CommandError, e
        end

        def resolve_conflicts(source_repository, resolution, source_branch:, target_branch:)
          wrapped_gitaly_errors do
            gitaly_conflicts_client(source_repository).resolve_conflicts(@target_repository, resolution, source_branch, target_branch)
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
      end
    end
  end
end
