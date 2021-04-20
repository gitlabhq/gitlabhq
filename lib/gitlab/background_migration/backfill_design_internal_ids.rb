# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill design.iid for a range of projects
    class BackfillDesignInternalIds
      # See app/models/internal_id
      # This is a direct copy of the application code with the following changes:
      # - usage enum is hard-coded to the value for design_management_designs
      # - init is not passed around, but ignored
      class InternalId < ActiveRecord::Base
        def self.track_greatest(subject, scope, new_value)
          InternalIdGenerator.new(subject, scope).track_greatest(new_value)
        end

        # Increments #last_value with new_value if it is greater than the current,
        # and saves the record
        #
        # The operation locks the record and gathers a `ROW SHARE` lock (in PostgreSQL).
        # As such, the increment is atomic and safe to be called concurrently.
        def track_greatest_and_save!(new_value)
          update_and_save { self.last_value = [last_value || 0, new_value].max }
        end

        private

        def update_and_save(&block)
          lock!
          yield
          # update_and_save_counter.increment(usage: usage, changed: last_value_changed?)
          save!
          last_value
        end
      end

      # See app/models/internal_id
      class InternalIdGenerator
        attr_reader :subject, :scope, :scope_attrs

        def initialize(subject, scope)
          @subject = subject
          @scope = scope

          raise ArgumentError, 'Scope is not well-defined, need at least one column for scope (given: 0)' if scope.empty?
        end

        # Create a record in internal_ids if one does not yet exist
        # and set its new_value if it is higher than the current last_value
        #
        # Note this will acquire a ROW SHARE lock on the InternalId record
        def track_greatest(new_value)
          subject.transaction do
            record.track_greatest_and_save!(new_value)
          end
        end

        def record
          @record ||= (lookup || create_record)
        end

        def lookup
          InternalId.find_by(**scope, usage: usage_value)
        end

        def usage_value
          10 # see Enums::InternalId - this is the value for design_management_designs
        end

        # Create InternalId record for (scope, usage) combination, if it doesn't exist
        #
        # We blindly insert without synchronization. If another process
        # was faster in doing this, we'll realize once we hit the unique key constraint
        # violation. We can safely roll-back the nested transaction and perform
        # a lookup instead to retrieve the record.
        def create_record
          subject.transaction(requires_new: true) do
            InternalId.create!(
              **scope,
              usage: usage_value,
              last_value: 0
            )
          end
        rescue ActiveRecord::RecordNotUnique
          lookup
        end
      end

      attr_reader :design_class

      def initialize(design_class)
        @design_class = design_class
      end

      def perform(relation)
        start_id, end_id = relation.pluck("min(project_id), max(project_id)").flatten
        table = 'design_management_designs'

        ActiveRecord::Base.connection.execute <<~SQL
          WITH
          starting_iids(project_id, iid) as #{Gitlab::Database::AsWithMaterialized.materialized_if_supported}(
            SELECT project_id, MAX(COALESCE(iid, 0))
            FROM #{table}
            WHERE project_id BETWEEN #{start_id} AND #{end_id}
            GROUP BY project_id
          ),
          with_calculated_iid(id, iid) as #{Gitlab::Database::AsWithMaterialized.materialized_if_supported}(
            SELECT design.id,
                   init.iid + ROW_NUMBER() OVER (PARTITION BY design.project_id ORDER BY design.id ASC)
              FROM #{table} as design, starting_iids as init
              WHERE design.project_id BETWEEN #{start_id} AND #{end_id}
                AND design.iid IS NULL
                AND init.project_id = design.project_id
          )

          UPDATE #{table}
             SET iid = with_calculated_iid.iid
            FROM with_calculated_iid
           WHERE #{table}.id = with_calculated_iid.id
        SQL

        # track the new greatest IID value
        relation.each do |design|
          current_max = design_class.where(project_id: design.project_id).maximum(:iid)
          scope = { project_id: design.project_id }
          InternalId.track_greatest(design, scope, current_max)
        end
      end
    end
  end
end
