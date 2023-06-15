# frozen_string_literal: true

module API
  module Admin
    class Dictionary < ::API::Base
      feature_category :database
      urgency :low

      before do
        authenticated_as_admin!
      end

      namespace 'admin' do
        resources 'databases/:database_name/dictionary/tables/:table_name' do
          desc 'Retrieve dictionary details' do
            success ::API::Entities::Dictionary::Table
            failure [
              { code: 401, message: '401 Unauthorized' },
              { code: 403, message: '403 Forbidden' },
              { code: 404, message: '404 Not found' }
            ]
          end
          params do
            requires :database_name,
              type: String,
              values: %w[main ci],
              desc: 'The database name'

            requires :table_name,
              type: String,
              desc: 'The table name'
          end
          get do
            not_found!('Table not found') unless File.exist?(safe_file_path!)

            present table_dictionary, with: Entities::Dictionary::Table
          end
        end

        helpers do
          def table_name
            params[:table_name]
          end

          def table_dictionary
            YAML.load_file(safe_file_path!).with_indifferent_access
          end

          def safe_file_path!
            dir = Gitlab::Database::GitlabSchema.dictionary_paths.first.to_s
            path = Rails.root.join(dir, "#{table_name}.yml").to_s

            Gitlab::PathTraversal.check_allowed_absolute_path_and_path_traversal!(path, [dir])

            path
          end
        end
      end
    end
  end
end
