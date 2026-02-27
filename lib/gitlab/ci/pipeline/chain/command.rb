# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        Command = Struct.new(
          :source, :project, :current_user,
          :origin_ref, :checkout_sha, :after_sha, :before_sha, :source_sha, :target_sha,
          :trigger, :schedule, :merge_request, :external_pull_request,
          :ignore_skip_ci, :save_incompleted,
          :seeds_block, :variables_attributes, :push_options,
          :chat_data, :mirror_update, :bridge, :content, :dry_run, :linting, :logger, :pipeline_policy_context,
          :duo_workflow_definition, :scan_profile_eligibility_service,
          # These attributes are set by Chains during processing:
          :config_content, :yaml_processor_result, :workflow_rules_result, :pipeline_seed,
          :pipeline_config, :partition_id, :inputs, :gitaly_context, :pipeline_creation_forced_to_continue,
          keyword_init: true
        ) do
          include Gitlab::Utils::StrongMemoize

          def readonly?
            dry_run? || linting?
          end

          def dry_run?
            dry_run
          end

          def linting?
            linting
          end

          def branch?
            if Feature.enabled?(:ci_pipeline_ref_resolution, project)
              ref_resolver.branch?
            else
              branch_exists?
            end
          end

          def tag?
            if Feature.enabled?(:ci_pipeline_ref_resolution, project)
              ref_resolver.tag?
            else
              tag_exists?
            end
          end

          def merge_request_ref?
            if Feature.enabled?(:ci_pipeline_ref_resolution, project)
              ref_resolver.merge_request?
            else
              merge_request_ref_exists?
            end
          end

          def workload?
            if Feature.enabled?(:ci_pipeline_ref_resolution, project)
              ref_resolver.workload?
            else
              workload_ref_exists?
            end
          end

          def ref
            Gitlab::Git.ref_name(origin_ref)
          end
          strong_memoize_attr :ref

          def ref_exists?
            resolved_ref.present?
          end
          strong_memoize_attr :ref_exists?

          def sha
            ref = if Feature.enabled?(:ci_pipeline_ref_resolution, project)
                    resolved_ref
                  else
                    origin_ref
                  end

            project.commit(origin_sha || ref).try(:id)
          end
          strong_memoize_attr :sha

          def origin_sha
            checkout_sha || after_sha
          end

          def before_sha
            self[:before_sha] || checkout_sha || Gitlab::Git::SHA1_BLANK_SHA
          end

          def protected_ref?
            strong_memoize(:protected_ref) do
              ref_to_check = if Feature.enabled?(:ci_pipeline_ref_resolution, project)
                               resolved_ref
                             else
                               origin_ref
                             end

              project.protected_for?(ref_to_check)
            end
          end

          def ambiguous_ref?
            if Feature.enabled?(:ci_pipeline_ref_resolution, project)
              ref_resolver.ambiguous?
            else
              strong_memoize(:ambiguous_ref) do
                project.repository.ambiguous_ref?(origin_ref)
              end
            end
          end

          def parent_pipeline
            bridge&.parent_pipeline
          end

          def parent_pipeline_partition_id
            parent_pipeline.partition_id if creates_child_pipeline?
          end

          def creates_child_pipeline?
            bridge&.triggers_child_pipeline?
          end

          def metrics
            @metrics ||= ::Gitlab::Ci::Pipeline::Metrics
          end

          def logger
            self[:logger] ||= ::Gitlab::Ci::Pipeline::Logger.new(project: project)
          end

          def current_pipeline_size
            # The `pipeline_seed` attribute is assigned after the Seed step.
            # And, the seed is populated when calling the `pipeline_seed.stages` method in Populate.
            # So, there is no guarantee that `pipeline_seed` will return a meaningful result.
            # If it does not, it's not important, we can just return 0.
            # This is also the reason why we don't "strong memoize" this method.
            pipeline_seed&.size || 0
          end

          def jobs_count_in_alive_pipelines
            project.all_pipelines.jobs_count_in_alive_pipelines
          end
          strong_memoize_attr :jobs_count_in_alive_pipelines

          def observe_step_duration(step_class, duration)
            step = step_class.name.underscore.parameterize(separator: '_')
            logger.observe("pipeline_step_#{step}_duration_s", duration, once: true)

            if Feature.enabled?(:ci_pipeline_creation_step_duration_tracking, type: :ops)
              metrics.pipeline_creation_step_duration_histogram
                .observe({ step: step_class.name }, duration.seconds)
            end
          end

          def observe_creation_duration(duration)
            logger.observe(:pipeline_creation_duration_s, duration, once: true)

            metrics.pipeline_creation_duration_histogram
              .observe({ gitlab: gitlab_org_project?.to_s }, duration.seconds)
          end

          def observe_pipeline_size(pipeline)
            logger.observe(:pipeline_size_count, pipeline.total_size, once: true)

            metrics.pipeline_size_histogram
              .observe({ source: pipeline.source.to_s, plan: project.actual_plan_name }, pipeline.total_size)
          end

          def observe_jobs_count_in_alive_pipelines
            metrics.active_jobs_histogram
              .observe({ plan: project.actual_plan_name }, jobs_count_in_alive_pipelines + current_pipeline_size)
          end

          def increment_pipeline_failure_reason_counter(reason)
            metrics.pipeline_failure_reason_counter
              .increment(reason: (reason || :unknown_failure).to_s)
          end

          def branch_exists?
            strong_memoize(:is_branch) do
              branch_ref? && project.repository.branch_exists?(ref)
            end
          end

          def tag_exists?
            strong_memoize(:is_tag) do
              tag_ref? && project.repository.tag_exists?(ref)
            end
          end

          def merge_request_ref_exists?
            check_merge_request_ref
          end

          def workload_ref_exists?
            ::Ci::Workloads::Workload.workload_ref?(origin_ref) && project.repository.ref_exists?(origin_ref)
          end

          private

          def resolved_ref
            ref_resolver.resolved_ref
          end
          strong_memoize_attr :resolved_ref

          def ref_resolver
            Gitlab::Git::RefResolver.new(project.repository, origin_ref)
          end
          strong_memoize_attr :ref_resolver

          def branch_ref?
            return true if full_git_ref_name_unavailable?

            Gitlab::Git.branch_ref?(origin_ref).present?
          end

          def tag_ref?
            return true if full_git_ref_name_unavailable?

            Gitlab::Git.tag_ref?(origin_ref).present?
          end

          def full_git_ref_name_unavailable?
            ref == origin_ref
          end

          def gitlab_org_project?
            project.full_path == 'gitlab-org/gitlab'
          end

          def check_merge_request_ref
            MergeRequest.merge_request_ref?(origin_ref) && project.repository.ref_exists?(origin_ref)
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Command.prepend_mod
