# frozen_string_literal: true

module API
  class ContainerRepositories < ::API::Base
    include Gitlab::Utils::StrongMemoize
    helpers ::API::Helpers::PackagesHelpers

    before { authenticate! }

    feature_category :container_registry

    namespace 'registry' do
      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :repositories, requirements: { id: /[0-9]*/ } do
        desc 'Get a container repository' do
          detail 'This feature was introduced in GitLab 13.6.'
          success Entities::ContainerRegistry::Repository
        end
        params do
          optional :tags, type: Boolean, default: false, desc: 'Determines if tags should be included'
          optional :tags_count, type: Boolean, default: false, desc: 'Determines if the tags count should be included'
        end
        get ':id' do
          authorize!(:read_container_image, repository)

          present repository, with: Entities::ContainerRegistry::Repository, tags: params[:tags], tags_count: params[:tags_count], user: current_user
        end
      end
    end

    helpers do
      def repository
        strong_memoize(:repository) do
          ContainerRepository.find(params[:id])
        end
      end
    end
  end
end
