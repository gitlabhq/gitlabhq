# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Create < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          BULK_INSERT_BATCH_SIZE = 500

          def perform!
            if Feature.enabled?(:ci_bulk_insert_pipeline_records, project)
              perform_with_bulk_insert!
            else
              logger.instrument_once_with_sql(:pipeline_save) do
                # It is still fine to save `::Ci::JobDefinition` objects even if the pipeline is not created due to some
                # reason because they can be used in the next pipeline creations.
                ::Gitlab::Ci::Pipeline::Create::JobDefinitionBuilder.new(pipeline, statuses).run

                with_build_hooks_via_chain do
                  BulkInsertableAssociations.with_bulk_insert do
                    pipeline.save!
                  end
                end
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
          rescue ActiveRecord::RecordNotUnique => e
            raise unless e.message.include?('iid')

            ::InternalId.flush_records!(project: project, usage: :ci_pipelines)
            error("Failed to persist the pipeline, please retry")
          end

          def break?
            !pipeline.persisted?
          end

          def perform_with_bulk_insert!
            with_iid_retry(cleanup_on_failure: true) do
              logger.instrument_once_with_sql(:pipeline_save) do
                ::Gitlab::Ci::Pipeline::Create::JobDefinitionBuilder.new(pipeline, statuses).run

                pipeline.validate!
                validate_records!(pipeline.stages)
                validate_records!(statuses)

                stages_to_insert = pipeline.stages.to_a
                statuses_to_insert = statuses.to_a

                pipeline.stages.clear

                pipeline.save!

                bulk_insert_stages!(stages_to_insert)
                bulk_insert_statuses!(statuses_to_insert)

                pipeline.association(:stages).target = stages_to_insert
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            error("Failed to persist the pipeline: #{e}")
            cleanup_bulk_insert_on_failure!
          end

          private

          def with_iid_retry(cleanup_on_failure: false)
            max_retries = 3
            retries = 0

            begin
              yield
            rescue ActiveRecord::RecordNotUnique => e
              raise unless e.message.include?('iid')

              ::InternalId.flush_records!(project: project, usage: :ci_pipelines)
              cleanup_bulk_insert_on_failure! if cleanup_on_failure

              pipeline.write_attribute(:iid, nil) unless pipeline.frozen?

              retries += 1
              retry if retries < max_retries

              raise
            end
          end

          def validate_records!(records)
            records.each(&:validate!)
          end

          def with_build_hooks_via_chain
            Gitlab::SafeRequestStore[:ci_triggering_build_hooks_via_chain] = true
            yield
          ensure
            Gitlab::SafeRequestStore.delete(:ci_triggering_build_hooks_via_chain)
          end

          def cleanup_bulk_insert_on_failure!
            return unless pipeline.persisted?

            pipeline.destroy!
          end

          def assign_pipeline_references!(records)
            records.each do |record|
              record.pipeline_id = pipeline.id
              record.partition_id = pipeline.partition_id
              record.project_id = pipeline.project_id
            end
          end

          def assign_build_attributes!(builds)
            builds.each do |build|
              build.commit_id = pipeline.id
              build.partition_id = pipeline.partition_id
              build.project_id = pipeline.project_id
              build.processed = false
              build.stage_id = build.ci_stage.id if build.ci_stage
            end
          end

          def bulk_insert_with_pipeline_refs!(model_class, records, returning: [:id])
            return if records.empty?

            assign_pipeline_references!(records)

            records.each_slice(BULK_INSERT_BATCH_SIZE) do |batch|
              insert_records_and_restore_ids(model_class, batch, returning: returning)
            end
          end

          def bulk_insert_stages!(stages)
            bulk_insert_with_pipeline_refs!(::Ci::Stage, stages)
          end

          def bulk_insert_statuses!(builds)
            return if builds.empty?

            assign_build_attributes!(builds)

            builds.each_slice(BULK_INSERT_BATCH_SIZE) do |batch|
              result = insert_records_and_restore_ids(::CommitStatus, batch, returning: [:id, :partition_id])
              bulk_insert_job_definition_instances!(batch, result)
            end

            bulk_insert_needs!(builds)
            bulk_insert_job_sources!(builds)
          end

          def bulk_insert_job_definition_instances!(builds, result)
            instances = builds.filter_map.with_index do |build, index|
              next unless build.job_definition_instance

              build.job_definition_instance.tap do |instance|
                instance.job_id = result[index]['id']
                instance.partition_id = result[index]['partition_id']
              end
            end

            return if instances.empty?

            insert_records_and_restore_ids(::Ci::JobDefinitionInstance, instances, returning: [])
          end

          def bulk_insert_needs!(builds)
            needs = builds.flat_map do |build|
              build.needs.map do |need|
                need.build_id = build.id
                need.partition_id = build.partition_id
                need.project_id ||= build.project_id
                need
              end
            end

            return if needs.empty?

            ::Ci::BuildNeed.bulk_insert!(needs, batch_size: BULK_INSERT_BATCH_SIZE)
          end

          def bulk_insert_job_sources!(builds)
            job_sources = builds.filter_map do |build|
              source = build.job_source
              next unless source

              source.tap do |s|
                s.build_id = build.id
                s.partition_id = build.partition_id
              end
            end

            return if job_sources.empty?

            job_sources.each_slice(BULK_INSERT_BATCH_SIZE) do |batch|
              insert_records_and_restore_ids(::Ci::BuildSource, batch, returning: [])
            end
          end

          def insert_records_and_restore_ids(model_class, records, returning:)
            if model_class.column_names.include?('created_at')
              timestamp = Time.current
              records.each do |record|
                record.created_at ||= timestamp
                record.updated_at ||= timestamp
              end
            end

            column_names = model_class.column_names - ['id']
            attributes = records.map { |record| record.attributes.slice(*column_names) }

            # Build SQL manually to avoid ActiveRecord's unique index validation on partitioned tables
            table_name = model_class.quoted_table_name
            columns = format_columns(model_class, column_names)

            values_list = attributes.map do |attrs|
              values = column_names.map do |col|
                value = attrs[col]
                type = model_class.type_for_attribute(col)
                serialized = type.serialize(value)
                model_class.connection.quote(serialized)
              end.join(', ')
              "(#{values})"
            end.join(', ')

            sql = "INSERT INTO #{table_name} (#{columns}) VALUES #{values_list}"
            sql += " RETURNING #{format_columns(model_class, returning)}" if returning.any?

            result = model_class.connection.execute(sql)

            restore_ids_from_result(records, result, returning)

            result
          end

          def format_columns(model_class, columns)
            columns.map { |c| model_class.connection.quote_column_name(c) }.join(', ')
          end

          def restore_ids_from_result(records, result, returning)
            if returning.any?
              result.to_a.each_with_index do |row_hash, index|
                returning.each do |field|
                  records[index].write_attribute(field, row_hash[field.to_s])
                end
                records[index].instance_variable_set(:@new_record, false)
              end
            else
              records.each { |record| record.instance_variable_set(:@new_record, false) }
            end
          end

          def statuses
            pipeline
              .stages
              .flat_map(&:statuses)
          end
          strong_memoize_attr :statuses
        end
      end
    end
  end
end
