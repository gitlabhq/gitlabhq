# frozen_string_literal: true

module API
  class DependencyProxy < ::API::Base
    helpers ::API::Helpers::PackagesHelpers

    feature_category :dependency_proxy

    helpers do
      def obtain_new_purge_cache_lease
        Gitlab::ExclusiveLease
          .new("dependency_proxy:delete_group_blobs:#{user_group.id}",
               timeout: 1.hour)
          .try_obtain
      end
    end

    before do
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

        message = 'This request has already been made. It may take some time to purge the cache. You can run this at most once an hour for a given group'
        render_api_error!(message, 409) unless obtain_new_purge_cache_lease

        # rubocop:disable CodeReuse/Worker
        PurgeDependencyProxyCacheWorker.perform_async(current_user.id, user_group.id)
        # rubocop:enable CodeReuse/Worker
      end
    end
  end
end
