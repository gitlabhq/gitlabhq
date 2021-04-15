# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        Command = Struct.new(
          :source, :project, :current_user,
          :origin_ref, :checkout_sha, :after_sha, :before_sha, :source_sha, :target_sha,
          :trigger_request, :schedule, :merge_request, :external_pull_request,
          :ignore_skip_ci, :save_incompleted,
          :seeds_block, :variables_attributes, :push_options,
          :chat_data, :allow_mirror_update, :bridge, :content, :dry_run,
          # These attributes are set by Chains during processing:
          :config_content, :yaml_processor_result, :workflow_rules_result, :pipeline_seed
        ) do
          include Gitlab::Utils::StrongMemoize

          def initialize(params = {})
            params.each do |key, value|
              self[key] = value
            end
          end

          alias_method :dry_run?, :dry_run

          def branch_exists?
            strong_memoize(:is_branch) do
              project.repository.branch_exists?(ref)
            end
          end

          def tag_exists?
            strong_memoize(:is_tag) do
              project.repository.tag_exists?(ref)
            end
          end

          def merge_request_ref_exists?
            strong_memoize(:merge_request_ref_exists) do
              MergeRequest.merge_request_ref?(origin_ref) &&
                project.repository.ref_exists?(origin_ref)
            end
          end

          def ref
            strong_memoize(:ref) do
              Gitlab::Git.ref_name(origin_ref)
            end
          end

          def sha
            strong_memoize(:sha) do
              project.commit(origin_sha || origin_ref).try(:id)
            end
          end

          def origin_sha
            checkout_sha || after_sha
          end

          def before_sha
            self[:before_sha] || checkout_sha || Gitlab::Git::BLANK_SHA
          end

          def protected_ref?
            strong_memoize(:protected_ref) do
              project.protected_for?(origin_ref)
            end
          end

          def ambiguous_ref?
            strong_memoize(:ambiguous_ref) do
              project.repository.ambiguous_ref?(origin_ref)
            end
          end

          def parent_pipeline
            bridge&.parent_pipeline
          end

          def creates_child_pipeline?
            bridge&.triggers_child_pipeline?
          end

          def metrics
            @metrics ||= ::Gitlab::Ci::Pipeline::Metrics
          end

          def observe_creation_duration(duration)
            metrics.pipeline_creation_duration_histogram
              .observe({}, duration.seconds)
          end

          def observe_pipeline_size(pipeline)
            metrics.pipeline_size_histogram
              .observe({ source: pipeline.source.to_s }, pipeline.total_size)
          end

          def increment_pipeline_failure_reason_counter(reason)
            metrics.pipeline_failure_reason_counter
              .increment(reason: (reason || :unknown_failure).to_s)
          end

          def dangling_build?
            %i[ondemand_dast_scan webide].include?(source)
          end
        end
      end
    end
  end
end
