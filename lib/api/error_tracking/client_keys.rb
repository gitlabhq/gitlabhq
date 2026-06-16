# frozen_string_literal: true

module API
  class ErrorTracking::ClientKeys < ::API::Base
    before { authenticate! }

    ERROR_TRACKING_CLIENT_KEYS_TAGS = %w[error_tracking].freeze
    feature_category :observability
    urgency :low

    params do
      requires :id, types: [String, Integer],
        desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/error_tracking' do
        before do
          authorize! :admin_operations, user_project
        end

        desc 'List all project client keys' do
          detail 'Lists all integrated error tracking client keys for a specified project.'
          success Entities::ErrorTracking::ClientKey
          is_array true
          tags ERROR_TRACKING_CLIENT_KEYS_TAGS
        end
        route_setting :authorization, permissions: :read_error_tracking_client_key, boundary_type: :project
        get '/client_keys' do
          collection = user_project.error_tracking_client_keys

          present paginate(collection), with: Entities::ErrorTracking::ClientKey
        end

        desc 'Create a client key' do
          detail 'Creates a client key for integrated error tracking in a specified project. The public key ' \
            'attribute is generated automatically.'
          success Entities::ErrorTracking::ClientKey
          tags ERROR_TRACKING_CLIENT_KEYS_TAGS
        end
        route_setting :authorization, permissions: :create_error_tracking_client_key, boundary_type: :project
        post '/client_keys' do
          key = user_project.error_tracking_client_keys.create!

          present key, with: Entities::ErrorTracking::ClientKey
        end

        desc 'Delete a client key' do
          detail 'Deletes an integrated error tracking client key from a specified project.'
          success Entities::ErrorTracking::ClientKey
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags ERROR_TRACKING_CLIENT_KEYS_TAGS
        end
        route_setting :authorization, permissions: :delete_error_tracking_client_key, boundary_type: :project
        delete '/client_keys/:key_id' do
          key = user_project.error_tracking_client_keys.find(params[:key_id])
          key.destroy!

          present key, with: Entities::ErrorTracking::ClientKey
        end
      end
    end
  end
end
