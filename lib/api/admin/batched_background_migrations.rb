# frozen_string_literal: true

module API
  module Admin
    class BatchedBackgroundMigrations < ::API::Base
      feature_category :database
      urgency :low

      before do
        authenticated_as_admin!
      end

      namespace 'admin' do
        params do
          requires :id, type: Integer, desc: 'ID of the batched background migration.'
        end
        resources 'batched_background_migrations/:id' do
          desc 'Retrieve a batched background migration' do
            detail 'Fetches details of a specific batched migration, with optional filtering by database target.'
            success ::API::Entities::BatchedBackgroundMigration
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' },
              { code: 404, message: '404 Not found' }
            ]
            tags %w[batched_background_migrations]
          end
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'Name of the database.',
              default: 'main'
            requires :id,
              type: Integer,
              desc: 'ID of the batched background migration.'
          end
          route_setting :authorization, permissions: :read_batched_background_migration, boundary_type: :instance,
            assignable_when: [:admin]
          get do
            Gitlab::Database::SharedModel.using_connection(base_model.connection) do
              present_entity(batched_background_migration)
            end
          end
        end

        resources 'batched_background_migrations' do
          desc 'Get the list of batched background migrations' do
            detail 'Lists all batched background migrations with optional filters for database and job class name.'
            success ::API::Entities::BatchedBackgroundMigration
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' }
            ]
            is_array true
            tags %w[batched_background_migrations]
          end
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'Name of the database.',
              default: 'main'
            optional :job_class_name,
              type: String,
              desc: 'Filter migrations by job class name.'
          end
          route_setting :authorization, permissions: :read_batched_background_migration, boundary_type: :instance,
            assignable_when: [:admin]
          get do
            Gitlab::Database::SharedModel.using_connection(base_model.connection) do
              migrations = Database::BatchedBackgroundMigrationsFinder.new(params: params).execute
              present_entity(migrations)
            end
          end
        end

        params do
          requires :id, type: Integer, desc: 'ID of the batched background migration.'
        end
        resources 'batched_background_migrations/:id/resume' do
          desc 'Resume a batched background migration' do
            detail 'Resumes execution of a previously paused batched background migration.'
            success ::API::Entities::BatchedBackgroundMigration
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' },
              { code: 404, message: '404 Not found' },
              { code: 422, message: 'You can resume only `paused` batched background migrations.' }
            ]
            tags %w[batched_background_migrations]
          end
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'Name of the database.',
              default: 'main'
            requires :id,
              type: Integer,
              desc: 'ID of the batched background migration.'
          end
          route_setting :authorization, permissions: :resume_batched_background_migration, boundary_type: :instance,
            assignable_when: [:admin]
          put do
            Gitlab::Database::SharedModel.using_connection(base_model.connection) do
              unless batched_background_migration.paused?
                msg = 'You can resume only `paused` batched background migrations.'
                render_api_error!(msg, 422)
              end

              batched_background_migration.execute!
              present_entity(batched_background_migration)
            end
          end
        end

        params do
          requires :id, type: Integer, desc: 'ID of the batched background migration.'
        end
        resources 'batched_background_migrations/:id/pause' do
          desc 'Pause a batched background migration' do
            detail 'Pauses an active batched background migration temporarily.'
            success ::API::Entities::BatchedBackgroundMigration
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' },
              { code: 404, message: '404 Not found' },
              { code: 422, message: 'You can pause only `active` batched background migrations.' }
            ]
            tags %w[batched_background_migrations]
          end
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'Name of the database.',
              default: 'main'
            requires :id,
              type: Integer,
              desc: 'ID of the batched background migration.'
          end
          route_setting :authorization, permissions: :pause_batched_background_migration, boundary_type: :instance,
            assignable_when: [:admin]
          put do
            Gitlab::Database::SharedModel.using_connection(base_model.connection) do
              unless batched_background_migration.active?
                msg = 'You can pause only `active` batched background migrations.'
                render_api_error!(msg, 422)
              end

              batched_background_migration.pause!
              present_entity(batched_background_migration)
            end
          end
        end
      end

      helpers do
        def batched_background_migration
          @batched_background_migration ||= Gitlab::Database::BackgroundMigration::BatchedMigration.find(params[:id])
        end

        def base_model
          database = params[:database] || Gitlab::Database::MAIN_DATABASE_NAME
          @base_model ||= Gitlab::Database.database_base_models[database]
        end

        # Force progress evaluation to occur now while we're using the right connection
        def present_entity(result)
          representation = entity_representation_for(::API::Entities::BatchedBackgroundMigration, result, {})
          json_representation = Gitlab::Json.dump(representation)

          body Gitlab::Json::Precompiled.new(json_representation)
        end
      end
    end
  end
end
