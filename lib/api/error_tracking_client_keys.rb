# frozen_string_literal: true

module API
  class ErrorTrackingClientKeys < ::API::Base
    before { authenticate! }

    feature_category :error_tracking

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/error_tracking' do
        before do
          authorize! :admin_operations, user_project
        end

        desc 'List all client keys' do
          detail 'This feature was introduced in GitLab 14.3.'
          success Entities::ErrorTracking::ClientKey
        end
        get '/client_keys' do
          collection = user_project.error_tracking_client_keys

          present paginate(collection), with: Entities::ErrorTracking::ClientKey
        end

        desc 'Create a client key' do
          detail 'This feature was introduced in GitLab 14.3.'
          success Entities::ErrorTracking::ClientKey
        end
        post '/client_keys' do
          key = user_project.error_tracking_client_keys.create!

          present key, with: Entities::ErrorTracking::ClientKey
        end

        desc 'Delete a client key' do
          detail 'This feature was introduced in GitLab 14.3.'
          success Entities::ErrorTracking::ClientKey
        end
        delete '/client_keys/:key_id' do
          key = user_project.error_tracking_client_keys.find(params[:key_id])
          key.destroy!
        end
      end
    end
  end
end
