# frozen_string_literal: true

module API
  class GroupContainerRepositories < ::API::Base
    include PaginationParams
    include ::API::Helpers::ContainerRegistryHelpers

    helpers ::API::Helpers::PackagesHelpers

    before { authorize_read_group_container_images! }

    feature_category :container_registry
    urgency :low

    REPOSITORY_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(
      tag_name: API::NO_SLASH_URL_PART_REGEX)

    params do
      requires :id, types: [String, Integer],
        desc: 'The ID or URL-encoded path of the group accessible by the authenticated user'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List registry repositories within a group' do
        detail 'Get a list of registry repositories in a group. This feature was introduced in GitLab 12.2.'
        success Entities::ContainerRegistry::Repository
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Group Not Found' }
        ]
        is_array true
        tags %w[container_registry]
      end
      params do
        use :pagination
      end
      get ':id/registry/repositories' do
        repositories = ContainerRepositoriesFinder.new(
          user: current_user, subject: user_group
        ).execute

        track_package_event('list_repositories', :container, namespace: user_group)

        present paginate(repositories), with: Entities::ContainerRegistry::Repository, tags: false, tags_count: false
      end
    end

    helpers do
      def authorize_read_group_container_images!
        authorize! :read_container_image, user_group
      end
    end
  end
end
