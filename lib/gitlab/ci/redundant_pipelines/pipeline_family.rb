# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      class PipelineFamily
        def initialize(pipeline)
          @pipeline = pipeline
        end

        def active?
          return true if pipeline.cancelable?

          members.cancelable.exists?
        end

        def cancel(auto_canceled_by:)
          cancelable_members.each do |member, cancel_mode|
            ::Ci::CancelPipelineService.new(
              pipeline: member,
              current_user: nil,
              auto_canceled_by_pipeline: auto_canceled_by,
              cascade_to_children: false,
              safe_cancellation: cancel_mode == :interruptible
            ).force_execute
          end
        end

        private

        attr_reader :pipeline

        def members
          @members ||= pipeline.self_and_project_descendants
        end

        def cancelable_members
          members.with_auto_cancel_policy_associations.filter_map do |member|
            cancel_mode = AutoCancelPolicy.new(member).cancel_mode

            [member, cancel_mode] if cancel_mode
          end
        end
      end
    end
  end
end
