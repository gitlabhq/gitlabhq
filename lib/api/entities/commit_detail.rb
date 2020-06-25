# frozen_string_literal: true

module API
  module Entities
    class CommitDetail < Commit
      expose :stats, using: Entities::CommitStats, if: :stats
      expose :status
      expose :project_id

      expose :last_pipeline do |commit, options|
        pipeline = commit.latest_pipeline if can_read_pipeline?

        ::API::Entities::PipelineBasic.represent(pipeline, options)
      end

      private

      def can_read_pipeline?
        Ability.allowed?(options[:current_user], :read_pipeline, object.latest_pipeline)
      end
    end
  end
end
