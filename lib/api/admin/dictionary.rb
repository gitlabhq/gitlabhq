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
            table_dictionary = ::Gitlab::Database::Dictionary.entry(params[:table_name])
            not_found!('Table not found') unless table_dictionary

            present table_dictionary, with: Entities::Dictionary::Table
          end
        end
      end
    end
  end
end
