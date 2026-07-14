# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeduplicatePipelineIids < BatchedMigrationJob
      job_arguments :partition_ids

      operation_name :deduplicate_pipeline_iids
      feature_category :continuous_integration

      tables_to_check_for_vacuum :p_ci_pipelines

      CI_PIPELINES_USAGE = 5 # Usage value of :ci_pipelines; see Enums::InternalId.usage_resources
      MAX_RETRIES = 3

      def perform
        each_sub_batch do |sub_batch|
          duplicates = find_duplicates(sub_batch)
          next if duplicates.empty?

          duplicate_copies(duplicates).group_by(&:project_id).each do |project_id, copies|
            reassign_iids(project_id, copies)
          end
        end
      end

      private

      # Detect the (project_id, iid) pairs in this sub-batch that also exist in lower partitions
      def find_duplicates(sub_batch)
        sql = <<~SQL.squish
          WITH relation AS MATERIALIZED (
            #{sub_batch.select(:project_id, :iid, :partition_id).limit(sub_batch_size).to_sql}
          ),
          filtered_relation AS MATERIALIZED (
            SELECT project_id, iid, partition_id
            FROM relation
            WHERE iid IS NOT NULL
            LIMIT #{sub_batch_size}
          )
          SELECT project_id, iid
          FROM filtered_relation
          WHERE EXISTS (
            SELECT 1
            FROM p_ci_pipelines
            WHERE
              p_ci_pipelines.partition_id < #{partition_ids.max}
              AND p_ci_pipelines.partition_id < filtered_relation.partition_id
              AND p_ci_pipelines.project_id = filtered_relation.project_id
              AND p_ci_pipelines.iid = filtered_relation.iid
          )
        SQL

        connection.select_rows(sql).uniq
      end

      # Fetch every pipeline carrying one of the duplicates, across all partitions.
      # We must reassign *all* of them because the uniqueness trigger deletes the shared
      # p_ci_pipeline_iids record whenever any copy's iid changes. On GitLab.com each
      # duplicate has at most 2 copies, so this returns at most 2 * sub_batch_size rows.
      def duplicate_copies(duplicates)
        arel = pipeline_model.arel_table

        pipeline_model
          .select(:id, :partition_id, :project_id)
          .where(arel.grouping([arel[:project_id], arel[:iid]]).in(Arel::Nodes::ValuesList.new(duplicates)))
          .to_a
      end

      def reassign_iids(project_id, copies)
        retries = 0

        begin
          new_iids = BulkInternalId.reserve(project_id, copies.size) { current_max_iid(project_id) }
          assign_iids(copies.zip(new_iids))
        rescue ActiveRecord::RecordNotUnique # rubocop:disable BackgroundMigration/AvoidSilentRescueExceptions -- Required to handle duplicates
          raise if (retries += 1) > MAX_RETRIES

          BulkInternalId.flush(project_id)
          retry
        end
      end

      # One bulk UPDATE per project. The constant partition_id IN (...) lets PostgreSQL prune the
      # target to the partitions actually holding these copies, instead of locking every partition.
      def assign_iids(copies_with_iids)
        rows = copies_with_iids.map { |copy, new_iid| [copy.id, copy.partition_id, new_iid] }
        partitions = rows.map { |_id, partition_id, _iid| partition_id }.uniq.join(', ')

        sql = <<~SQL.squish
          UPDATE p_ci_pipelines AS p
          SET iid = v.new_iid, lock_version = p.lock_version + 1
          FROM (#{Arel::Nodes::ValuesList.new(rows).to_sql}) AS v (id, partition_id, new_iid)
          WHERE p.id = v.id AND p.partition_id = v.partition_id AND p.partition_id IN (#{partitions})
        SQL

        connection.execute(sql)
      end

      def pipeline_model
        @pipeline_model ||= define_batchable_model(:p_ci_pipelines, connection: connection, primary_key: :id)
      end

      def pipeline_iid_model
        @pipeline_iid_model ||= define_batchable_model(:p_ci_pipeline_iids, connection: connection)
      end

      # Mirrors Ci::Pipeline's iid init. We don't need Ci::Pipeline init's `|| count` fallback
      # because we're only dealing with projects that already have duplicate iids.
      def current_max_iid(project_id)
        scope = { project_id: project_id }

        [pipeline_iid_model.where(**scope).maximum(:iid),
          pipeline_model.where(**scope).maximum(:iid)].compact.max
      end

      # Similar to the InternalId class but handles iids in bulk
      class BulkInternalId < ApplicationRecord
        self.table_name = 'internal_ids'

        class << self
          def reserve(project_id, count, &init)
            last_value = update_record(project_id, count) || create_record(project_id, count, &init)

            ((last_value - count + 1)..last_value).to_a
          end

          def flush(project_id)
            where(project_id: project_id, usage: CI_PIPELINES_USAGE).delete_all
          end

          private

          # Returns nil if the record doesn't already exist
          def update_record(project_id, count)
            sql = sanitize_sql_array(
              [<<~SQL, count, project_id, CI_PIPELINES_USAGE]
                UPDATE internal_ids
                SET last_value = last_value + ?
                WHERE project_id = ? AND usage = ?
                RETURNING last_value
              SQL
            )

            connection.select_value(sql)
          end

          # On conflict, updates the record
          def create_record(project_id, count)
            floor = yield

            sql = sanitize_sql_array(
              [<<~SQL, project_id, CI_PIPELINES_USAGE, floor + count, floor, count]
                INSERT INTO internal_ids (project_id, usage, last_value)
                VALUES (?, ?, ?)
                ON CONFLICT (usage, project_id) WHERE project_id IS NOT NULL
                DO UPDATE SET last_value = GREATEST(internal_ids.last_value, ?) + ?
                RETURNING last_value
              SQL
            )

            connection.select_value(sql)
          end
        end
      end
    end
  end
end
