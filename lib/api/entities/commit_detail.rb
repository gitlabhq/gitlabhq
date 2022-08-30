# frozen_string_literal: true

module API
  module Entities
    class CommitDetail < Commit
      include ::API::Helpers::Presentable

      expose :stats, using: Entities::CommitStats, if: :include_stats
      expose :status_for, as: :status
      expose :project_id

      expose :last_pipeline do |commit, options|
        pipeline = commit.last_pipeline if can_read_pipeline?
        ::API::Entities::Ci::PipelineBasic.represent(pipeline, options)
      end

      private

      def can_read_pipeline?
        Ability.allowed?(options[:current_user], :read_pipeline, object.last_pipeline)
      end
    end
  end
end
