# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Context
        class Base
          include Gitlab::Utils::StrongMemoize

          attr_reader :pipeline

          def initialize(pipeline)
            @pipeline = pipeline
          end

          def variables
            raise NotImplementedError
          end

          def variables_hash
            strong_memoize(:variables_hash) do
              variables.to_hash
            end
          end

          def project
            pipeline.project
          end

          def sha
            pipeline.sha
          end

          def top_level_worktree_paths
            strong_memoize(:top_level_worktree_paths) do
              project.repository.tree(sha).blobs.map(&:path)
            end
          end

          def all_worktree_paths
            strong_memoize(:all_worktree_paths) do
              project.repository.ls_files(sha)
            end
          end

          protected

          def pipeline_attributes
            {
              pipeline: pipeline,
              project: pipeline.project,
              user: pipeline.user,
              ref: pipeline.ref,
              tag: pipeline.tag,
              trigger_request: pipeline.legacy_trigger,
              protected: pipeline.protected_ref?
            }
          end
        end
      end
    end
  end
end
