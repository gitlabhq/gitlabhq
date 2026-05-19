# frozen_string_literal: true

module API
  class Databases < ::API::Base
    feature_category :database
    urgency :low

    before do
      authenticate!
    end

    resources 'databases/:database_name/dictionary/tables' do
      desc 'List dictionary tables' do
        detail 'Returns database dictionary tables filtered by database and optional table size'
        success ::API::Entities::Dictionary::Table
        is_array true
        failure [
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
        tags %w[database_dictionary]
      end
      params do
        requires :database_name,
          type: String,
          values: Gitlab::Database.all_database_names,
          desc: 'The database name'

        optional :table_size,
          type: String,
          values: %w[small medium large over_limit],
          desc: 'Filter by table size classification'
      end
      route_setting :authorization, permissions: :read_database_dictionary, boundary_type: :instance
      get do
        allowed_schemas = schemas_for_database
        entries = ::Gitlab::Database::Dictionary.entries.select { |e| allowed_schemas.include?(e.gitlab_schema) }
        entries = entries.select { |e| e.table_size == params[:table_size] } if params[:table_size]

        present entries, with: Entities::Dictionary::Table
      end
    end

    helpers do
      def schemas_for_database
        db_info = ::Gitlab::Database.all_database_connections[params[:database_name]]
        db_info.gitlab_schemas.map(&:to_s).to_set
      end
    end
  end
end
