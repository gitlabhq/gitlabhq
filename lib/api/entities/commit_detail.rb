# frozen_string_literal: true

module API
  module Entities
    class CommitDetail < Commit
      include ::API::Helpers::Presentable

      expose :stats, using: Entities::CommitStats, if: :include_stats
      expose :status_for, as: :status, documentation: { type: 'string', example: 'success' }
      expose :project_id, documentation: { type: 'integer', example: 1 }

      expose :last_pipeline, documentation: { type: ::API::Entities::Ci::PipelineBasic.to_s } do |commit, options|
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
