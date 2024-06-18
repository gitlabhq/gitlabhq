# frozen_string_literal: true

module API
  class DependencyProxy < ::API::Base
    helpers ::API::Helpers::PackagesHelpers

    feature_category :virtual_registry
    urgency :low

    after_validation do
      authorize! :admin_group, user_group
    end

    params do
      requires :id, types: [String, Integer],
        desc: 'The ID or URL-encoded path of the group owned by the authenticated user'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Purge the dependency proxy for a group' do
        detail 'Schedules for deletion the cached manifests and blobs for a group.'\
          'This endpoint requires the Owner role for the group.'
        success code: 202
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
        tags %w[dependency_proxy]
      end
      delete ':id/dependency_proxy/cache' do
        not_found! unless user_group.dependency_proxy_feature_available?

        # rubocop:disable CodeReuse/Worker
        PurgeDependencyProxyCacheWorker.perform_async(current_user.id, user_group.id)
        # rubocop:enable CodeReuse/Worker

        status :accepted
      end
    end
  end
end
