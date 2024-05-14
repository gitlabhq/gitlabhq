# frozen_string_literal: true

module API
  class FeatureFlagsUserLists < ::API::Base
    include PaginationParams

    feature_flags_user_lists_tags = %w[feature_flags_user_lists]

    error_formatter :json, ->(message, _backtrace, _options, _env, _original_exception) {
      message.is_a?(String) ? { message: message }.to_json : message.to_json
    }

    feature_category :feature_flags
    urgency :low

    before do
      authorize_admin_feature_flags_user_lists!
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource 'projects/:id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :feature_flags_user_lists do
        desc 'List all feature flag user lists for a project' do
          detail 'Gets all feature flag user lists for the requested project. ' \
                 'This feature was introduced in GitLab 12.10.'
          success ::API::Entities::FeatureFlag::UserList
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags feature_flags_user_lists_tags
        end
        params do
          optional :search, type: String, desc: 'Return user lists matching the search criteria'

          use :pagination
        end
        get do
          user_lists = ::FeatureFlagsUserListsFinder.new(user_project, current_user, params).execute
          present paginate(user_lists),
            with: ::API::Entities::FeatureFlag::UserList
        end

        desc 'Create a feature flag user list' do
          detail 'Creates a feature flag user list. This feature was introduced in GitLab 12.10.'
          success ::API::Entities::FeatureFlag::UserList
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags feature_flags_user_lists_tags
        end
        params do
          requires :name, type: String, desc: 'The name of the list'
          requires :user_xids, type: String, desc: 'A comma separated list of external user ids'
        end
        post do
          # TODO: Move the business logic to a service class in app/services/feature_flags.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/367021
          list = user_project.operations_feature_flags_user_lists.create(declared_params)

          if list.save
            update_last_feature_flag_updated_at!

            present list, with: ::API::Entities::FeatureFlag::UserList
          else
            render_api_error!(list.errors.full_messages, :bad_request)
          end
        end
      end

      params do
        requires :iid, types: [String, Integer], desc: "The internal ID of the project's feature flag user list"
      end
      resource 'feature_flags_user_lists/:iid' do
        desc 'Get a feature flag user list' do
          detail 'Gets a feature flag user list. This feature was introduced in GitLab 12.10.'
          success ::API::Entities::FeatureFlag::UserList
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags feature_flags_user_lists_tags
        end
        get do
          present user_project.operations_feature_flags_user_lists.find_by_iid!(params[:iid]),
            with: ::API::Entities::FeatureFlag::UserList
        end

        desc 'Update a feature flag user list' do
          detail 'Updates a feature flag user list. This feature was introduced in GitLab 12.10.'
          success ::API::Entities::FeatureFlag::UserList
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags feature_flags_user_lists_tags
        end
        params do
          optional :name, type: String, desc: 'The name of the list'
          optional :user_xids, type: String, desc: 'A comma separated list of external user ids'
        end
        put do
          # TODO: Move the business logic to a service class in app/services/feature_flags.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/367021
          list = user_project.operations_feature_flags_user_lists.find_by_iid!(params[:iid])

          if list.update(declared_params(include_missing: false))
            update_last_feature_flag_updated_at!

            present list, with: ::API::Entities::FeatureFlag::UserList
          else
            render_api_error!(list.errors.full_messages, :bad_request)
          end
        end

        desc 'Delete feature flag user list' do
          detail 'Deletes a feature flag user list. This feature was introduced in GitLab 12.10.'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' },
            { code: 409, message: 'Conflict' }
          ]
          tags feature_flags_user_lists_tags
        end
        delete do
          # TODO: Move the business logic to a service class in app/services/feature_flags.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/367021
          list = user_project.operations_feature_flags_user_lists.find_by_iid!(params[:iid])
          if list.destroy
            update_last_feature_flag_updated_at!

            nil
          else
            render_api_error!(list.errors.full_messages, :conflict)
          end
        end
      end
    end

    helpers do
      def authorize_admin_feature_flags_user_lists!
        authorize! :admin_feature_flags_user_lists, user_project
      end

      def update_last_feature_flag_updated_at!
        Operations::FeatureFlagsClient.update_last_feature_flag_updated_at!(user_project)
      end
    end
  end
end
