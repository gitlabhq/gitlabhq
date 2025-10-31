# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Queueable
        extend ActiveSupport::Concern

        DEFAULT_BATCH_VALUES = {
          batch_size: 1_000,
          sub_batch_size: 100,
          min_cursor: [1],
          interval: 2.minutes,
          batch_class_name: 'PrimaryKeyBatchingStrategy',
          pause_ms: 100
        }.freeze

        EXISTING_OPERATION_MSG = <<~MSG
          Background Operation not enqueued because there is already an active operation with
          job_class_name: %s, table_name: %s, column_name: %s and job_arguments: [%s].
        MSG

        class_methods do
          def enqueue(
            job_class_name,
            table_name,
            column_name,
            job_arguments: [],
            gitlab_schema: nil,
            user: nil,
            **options
          )
            # background operation workers will be stored in the same database (eg: main, ci)
            # as the table it's operating on.
            operation_schema, operation_connection = table_connection_info(table_name)
            gitlab_schema ||= operation_schema

            Gitlab::Database::SharedModel.using_connection(operation_connection) do
              config = [job_class_name, table_name, column_name, job_arguments]

              if unfinished_with_config(*config, org_id: user&.organization_id).exists?
                Gitlab::AppLogger.warn(
                  format(EXISTING_OPERATION_MSG, job_class_name, table_name, column_name, job_arguments.join(', '))
                )

                return # rubocop:disable Cop/AvoidReturnFromBlocks -- Don't want to execute lines after the blocks (if any)
              end

              create_operation!(
                operation_connection,
                job_class_name,
                table_name,
                column_name,
                job_arguments,
                gitlab_schema,
                user,
                **options)
            end
          end

          def table_connection_info(table_name)
            table_schema = Gitlab::Database::GitlabSchema.table_schema!(table_name)
            base_model = Gitlab::Database.schemas_to_base_models[table_schema.to_s].first

            [table_schema, base_model.connection]
          end

          private

          # rubocop:disable Metrics/ParameterLists -- needs many arguments
          def create_operation!(
            connection,
            job_class_name,
            table_name,
            column_name,
            job_arguments,
            gitlab_schema,
            user,
            min_cursor: nil,
            max_cursor: nil,
            batch_size: DEFAULT_BATCH_VALUES[:batch_size],
            sub_batch_size: DEFAULT_BATCH_VALUES[:sub_batch_size],
            interval: DEFAULT_BATCH_VALUES[:interval],
            pause_ms: DEFAULT_BATCH_VALUES[:pause_ms],
            batch_class_name: DEFAULT_BATCH_VALUES[:batch_class_name]
          )
            interval = DEFAULT_BATCH_VALUES[:interval] if interval < DEFAULT_BATCH_VALUES[:interval]

            unless min_cursor.present?
              min_cursor = [get_column_value(connection, table_name, column_name, 'MIN')] ||
                DEFAULT_BATCH_VALUES[:min_cursor]
            end

            unless max_cursor.present?
              max_cursor = [get_column_value(connection, table_name, column_name, 'MAX')] || min_cursor
            end

            operation_attrs = {
              job_class_name: job_class_name,
              table_name: table_name,
              column_name: column_name,
              job_arguments: job_arguments,
              interval: interval,
              min_cursor: min_cursor,
              max_cursor: max_cursor,
              batch_size: batch_size,
              sub_batch_size: sub_batch_size,
              pause_ms: pause_ms,
              batch_class_name: batch_class_name,
              status: :queued,
              gitlab_schema: gitlab_schema
            }

            operation_attrs.merge!(user_id: user.id, organization_id: user.organization_id) if user.present?

            create!(operation_attrs)
          end
          # rubocop:enable Metrics/ParameterLists

          def get_column_value(connection, table_name, column_name, function)
            connection.select_value(<<~SQL)
              SELECT #{function}(#{Gitlab::Database.quote_column_name(column_name)})
              FROM #{Gitlab::Database.quote_table_name(table_name)}
            SQL
          end
        end
      end
    end
  end
end
