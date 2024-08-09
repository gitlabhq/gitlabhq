# frozen_string_literal: true

module Ci
  module JobArtifacts
    class ExpireProjectBuildArtifactsService
      BATCH_SIZE = 1000

      def initialize(project_id, expiry_time)
        @project_id = project_id
        @expiry_time = expiry_time
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def execute
        scope = Ci::JobArtifact.select(:id).for_project(project_id).order(:id)
        file_type_values = Ci::JobArtifact.erasable_file_types.map { |file_type| [Ci::JobArtifact.file_types[file_type]] }
        from_sql = Arel::Nodes::Grouping.new(Arel::Nodes::ValuesList.new(file_type_values)).as('file_types (file_type)').to_sql
        array_scope = Ci::JobArtifact.from(from_sql).select(:file_type)
        array_mapping_scope = ->(file_type_expression) { Ci::JobArtifact.where(Ci::JobArtifact.arel_table[:file_type].eq(file_type_expression)) }

        Gitlab::Pagination::Keyset::Iterator
          .new(scope: scope, in_operator_optimization_options: { array_scope: array_scope, array_mapping_scope: array_mapping_scope })
          .each_batch(of: BATCH_SIZE) do |batch|
          ids = batch.to_a.map(&:id)
          Ci::JobArtifact.unlocked.where(id: ids).update_all(locked: Ci::JobArtifact.lockeds[:unlocked], expire_at: expiry_time)
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      private

      attr_reader :project_id, :expiry_time
    end
  end
end
