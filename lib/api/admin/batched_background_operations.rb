# frozen_string_literal: true

module API
  module Admin
    class BatchedBackgroundOperations < ::API::Base
      feature_category :database
      urgency :low

      before do
        authenticated_as_admin!
      end

      namespace 'admin' do
        resources 'batched_background_operations' do
          desc 'Get the list of batched background operations' do
            detail 'This feature was introduced in GitLab 19.1.'
            success ::API::Entities::BatchedBackgroundOperation
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' }
            ]
            is_array true
            tags %w[batched_background_operations]
          end
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'The name of the database, the default `main`',
              default: 'main'
            optional :job_class_name,
              type: String,
              desc: 'Filter operations by job class name.'
          end
          route_setting :authorization, permissions: :read_batched_background_operation, boundary_type: :instance
          get do
            Gitlab::Database::SharedModel.using_connection(base_model.connection) do
              operations = ::Database::BatchedBackgroundOperationsCellLocalFinder.new(params: params).execute
              present_entity(operations)
            end
          end

          params do
            requires :id,
              type: Integer,
              desc: 'The batched background operation id'
          end
          route_param :id do
            desc 'Retrieve a batched background operation' do
              detail 'This feature was introduced in GitLab 19.1.'
              success ::API::Entities::BatchedBackgroundOperation
              failure [
                { code: 401, message: '401 Unauthorized' },
                { code: 403, message: '403 Forbidden' },
                { code: 404, message: '404 Not found' }
              ]
              tags %w[batched_background_operations]
            end
            params do
              optional :database,
                type: String,
                values: Gitlab::Database.all_database_names,
                desc: 'The name of the database',
                default: 'main'
            end
            route_setting :authorization, permissions: :read_batched_background_operation, boundary_type: :instance
            get do
              Gitlab::Database::SharedModel.using_connection(base_model.connection) do
                not_found!('Batched background operation') unless batched_background_operation
                present_entity(batched_background_operation)
              end
            end

            desc 'Stop a batched background operation' do
              detail 'This feature was introduced in GitLab 19.2.'
              success ::API::Entities::BatchedBackgroundOperation
              failure [
                { code: 401, message: '401 Unauthorized' },
                { code: 403, message: '403 Forbidden' },
                { code: 404, message: '404 Not found' },
                { code: 422, message: 'You can stop only `queued`, `active` or `paused` operations.' }
              ]
              tags %w[batched_background_operations]
            end
            params do
              optional :database,
                type: String,
                values: Gitlab::Database.all_database_names,
                desc: 'The name of the database',
                default: 'main'
            end
            route_setting :authorization, permissions: :stop_batched_background_operation, boundary_type: :instance
            put 'stop' do
              Gitlab::Database::SharedModel.using_connection(base_model.connection) do
                not_found!('Batched background operation') unless batched_background_operation

                unless batched_background_operation.stop
                  msg = 'You can stop only `queued`, `active` or `paused` operations.'
                  render_api_error!(msg, 422)
                end

                present_entity(batched_background_operation)
              end
            end

            desc 'Restart a batched background operation' do
              detail 'This feature was introduced in GitLab 19.2.'
              success ::API::Entities::BatchedBackgroundOperation
              failure [
                { code: 401, message: '401 Unauthorized' },
                { code: 403, message: '403 Forbidden' },
                { code: 404, message: '404 Not found' },
                { code: 422, message: 'You can restart only `stopped` operations.' }
              ]
              tags %w[batched_background_operations]
            end
            params do
              optional :database,
                type: String,
                values: Gitlab::Database.all_database_names,
                desc: 'The name of the database',
                default: 'main'
            end
            route_setting :authorization, permissions: :restart_batched_background_operation, boundary_type: :instance
            put 'restart' do
              Gitlab::Database::SharedModel.using_connection(base_model.connection) do
                not_found!('Batched background operation') unless batched_background_operation

                unless batched_background_operation.restart
                  msg = 'You can restart only `stopped` operations.'
                  render_api_error!(msg, 422)
                end

                present_entity(batched_background_operation)
              end
            end
          end
        end
      end

      helpers do
        def batched_background_operation
          @batched_background_operation ||=
            Gitlab::Database::BackgroundOperation::WorkerCellLocal.find_by_id(params[:id])
        end

        def base_model
          @base_model ||= begin
            database = params[:database] || Gitlab::Database::MAIN_DATABASE_NAME
            Gitlab::Database.database_base_models[database]
          end
        end

        # Force entity evaluation to occur now while we're using the right connection
        def present_entity(result)
          body Gitlab::Json::Precompiled.new(json_representation_for(result))
        end

        private

        def json_representation_for(result)
          representation = entity_representation_for(::API::Entities::BatchedBackgroundOperation, result, {})
          Gitlab::Json.dump(representation)
        end
      end
    end
  end
end
