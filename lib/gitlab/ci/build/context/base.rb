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
              if ci_optimize_memory_for_variables_enabled?
                variables.to_hash
              else
                variables.to_hash_legacy
              end
            end
          end

          def variables_hash_expanded
            strong_memoize(:variables_hash_expanded) do
              if ci_optimize_memory_for_variables_enabled?
                variables_sorted_and_expanded.to_hash
              else
                variables_sorted_and_expanded.to_hash_legacy
              end
            end
          end

          def variables_sorted_and_expanded
            strong_memoize(:variables_sorted_and_expanded) do
              variables.sort_and_expand_all
            end
          end

          def project
            pipeline.project
          end

          def sha
            pipeline.sha
          end

          delegate :top_level_worktree_paths, :all_worktree_paths, to: :pipeline

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

          def ci_optimize_memory_for_variables_enabled?
            ::Feature.enabled?(:ci_optimize_memory_for_variables, project)
          end
          strong_memoize_attr :ci_optimize_memory_for_variables_enabled?
        end
      end
    end
  end
end
