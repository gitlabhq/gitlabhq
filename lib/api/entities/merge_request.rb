# frozen_string_literal: true

module API
  module Entities
    class MergeRequest < MergeRequestBasic
      expose :subscribed, if: ->(_, options) { options.fetch(:include_subscribed, true) } do |merge_request, options|
        merge_request.subscribed?(options[:current_user], options[:project])
      end

      expose :changes_count do |merge_request, _options|
        merge_request.merge_request_diff.real_size
      end

      expose :latest_build_started_at, if: ->(_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.latest_build_started_at
      end

      expose :latest_build_finished_at, if: ->(_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.latest_build_finished_at
      end

      expose :first_deployed_to_production_at, if: ->(_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.first_deployed_to_production_at
      end

      expose :pipeline, using: Entities::Ci::PipelineBasic, if: ->(_, options) { build_available?(options) } do |merge_request, _options|
        merge_request.metrics&.pipeline
      end

      expose :head_pipeline, using: '::API::Entities::Ci::Pipeline', if: ->(_, options) do
        Ability.allowed?(options[:current_user], :read_pipeline, options[:project])
      end

      expose :diff_refs, using: Entities::DiffRefs

      # Allow the status of a rebase to be determined
      expose :merge_error
      expose :rebase_in_progress?, as: :rebase_in_progress, if: ->(_, options) { options[:include_rebase_in_progress] }

      expose :diverged_commits_count, as: :diverged_commits_count, if: ->(_, options) { options[:include_diverged_commits_count] }

      # We put this into an option because list of TODOs API will attach their
      # targets with Entities::MergeRequest instead of
      # Entities::MergeRequestBasic, but this attribute cannot be eagerly
      # loaded in batch for now. The list of merge requests API will
      # use Entities::MergeRequestBasic which does not support this, and
      # we always enable this for the single merge request API. This way
      # we avoid N+1 queries in the TODOs API and can still enable it for
      # the single merge request API.
      expose :first_contribution?, as: :first_contribution, if: ->(_, options) { options[:include_first_contribution] }

      def build_available?(options)
        options[:project]&.feature_available?(:builds, options[:current_user])
      end

      expose :user do
        expose :can_merge do |merge_request, options|
          merge_request.can_be_merged_by?(options[:current_user])
        end
      end
    end
  end
end
