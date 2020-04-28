# frozen_string_literal: true

module API
  class GroupContainerRepositories < Grape::API
    include PaginationParams

    before { authorize_read_group_container_images! }

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
        optional :tags, type: Boolean, default: false, desc: 'Determines if tags should be included'
      end
      get ':id/registry/repositories' do
        repositories = ContainerRepositoriesFinder.new(
          user: current_user, subject: user_group
        ).execute

        track_event('list_repositories')

        present paginate(repositories), with: Entities::ContainerRegistry::Repository, tags: params[:tags]
      end
    end

    helpers do
      def authorize_read_group_container_images!
        authorize! :read_container_image, user_group
      end
    end
  end
end
