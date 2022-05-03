# frozen_string_literal: true

module API
  class GroupContainerRepositories < ::API::Base
    include PaginationParams
    include ::API::Helpers::ContainerRegistryHelpers

    helpers ::API::Helpers::PackagesHelpers

    before { authorize_read_group_container_images! }

    feature_category :container_registry

    REPOSITORY_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(
      tag_name: API::NO_SLASH_URL_PART_REGEX)

    params do
      requires :id, type: String, desc: "Group's ID or path"
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of all repositories within a group' do
        detail 'This feature was introduced in GitLab 12.2.'
        success Entities::ContainerRegistry::Repository
      end
      params do
        use :pagination
      end
      get ':id/registry/repositories' do
        repositories = ContainerRepositoriesFinder.new(
          user: current_user, subject: user_group
        ).execute

        track_package_event('list_repositories', :container, user: current_user, namespace: user_group)

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
