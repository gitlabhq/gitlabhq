# frozen_string_literal: true

module API
  module Admin
    class Migrations < ::API::Base
      feature_category :database
      urgency :low

      before do
        authenticated_as_admin!
      end

      namespace 'admin' do
        resource 'migrations', only: [] do
          desc 'List pending database migrations' do
            success [
              { code: 200, message: '200 OK' }
            ]
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' }
            ]
            tags %w[migrations]
          end
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'The name of the database',
              default: 'main'
          end
          get 'pending' do
            response = Database::ListMigrationsService.new(
              connection: base_model.connection,
              status: 'pending'
            ).execute

            pending_migrations = response.payload[:migrations]

            present({
              pending_migrations: pending_migrations,
              database: params[:database] || 'main',
              total_pending: pending_migrations.size
            })
          end
        end

        resources 'migrations/:timestamp/mark' do
          desc 'Mark the migration as successfully executed' do
            success [
              { code: 201, message: '201 Created' }
            ]
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' },
              { code: 404, message: '404 Not found' },
              { code: 422, message: 'You can mark only pending migrations' }
            ]
            tags %w[migrations]
          end
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'The name of the database',
              default: 'main'
            requires :timestamp,
              type: Integer,
              desc: 'The migration version timestamp'
          end
          route_setting :authorization, permissions: :mark_database_migration, boundary_type: :instance
          post do
            response = Database::MarkMigrationService.new(
              connection: base_model.connection,
              version: params[:timestamp]
            ).execute

            if response.success?
              created!
            elsif response.reason == :not_found
              not_found!
            else
              render_api_error!('You can mark only pending migrations', 422)
            end
          end
        end
      end

      helpers do
        def base_model
          database = params[:database] || Gitlab::Database::MAIN_DATABASE_NAME
          @base_model ||= Gitlab::Database.database_base_models[database]

          not_found!("Database '#{database}' is not configured") unless @base_model

          @base_model
        end
      end
    end
  end
end
