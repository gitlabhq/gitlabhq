# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class SetDefaultIterationCadences
      class Iteration < ApplicationRecord
        self.table_name = 'sprints'
      end

      class IterationCadence < ApplicationRecord
        self.table_name = 'iterations_cadences'

        include BulkInsertSafe
      end

      class Group < ApplicationRecord
        self.table_name = 'namespaces'

        self.inheritance_column = :_type_disabled
      end

      def perform(*group_ids)
        create_iterations_cadences(group_ids)
        assign_iterations_cadences(group_ids)
      end

      private

      def create_iterations_cadences(group_ids)
        groups_with_cadence = IterationCadence.select(:group_id)

        new_cadences = Group.where(id: group_ids).where.not(id: groups_with_cadence).map do |group|
          last_iteration = Iteration.where(group_id: group.id).order(:start_date)&.last

          next unless last_iteration

          time = Time.now
          IterationCadence.new(
            group_id: group.id,
            title: "#{group.name} Iterations",
            start_date: last_iteration.start_date,
            last_run_date: last_iteration.start_date,
            automatic: false,
            created_at: time,
            updated_at: time
          )
        end

        IterationCadence.bulk_insert!(new_cadences.compact, skip_duplicates: true)
      end

      def assign_iterations_cadences(group_ids)
        IterationCadence.where(group_id: group_ids).each do |cadence|
          Iteration.where(iterations_cadence_id: nil).where(group_id: cadence.group_id).update_all(iterations_cadence_id: cadence.id)
        end
      end
    end
  end
end
