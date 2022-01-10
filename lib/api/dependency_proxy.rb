# frozen_string_literal: true

module API
  class DependencyProxy < ::API::Base
    helpers ::API::Helpers::PackagesHelpers

    feature_category :dependency_proxy

    after_validation do
      authorize! :admin_group, user_group
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Deletes all dependency_proxy_blobs for a group' do
        detail 'This feature was introduced in GitLab 12.10'
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
