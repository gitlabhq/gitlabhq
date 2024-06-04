# frozen_string_literal: true

module API
  module Ci
    class ResourceGroups < ::API::Base
      include PaginationParams

      ci_resource_groups_tags = %w[ci_resource_groups]

      RESOURCE_GROUP_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS
                                        .merge(key: API::NO_SLASH_URL_PART_REGEX)

      before { authenticate! }

      feature_category :continuous_delivery
      urgency :low

      params do
        requires :id,
          types: [String, Integer],
          desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
      end
      resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get all resource groups for a project' do
          success Entities::Ci::ResourceGroup
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags ci_resource_groups_tags
        end
        params do
          use :pagination
        end
        get ':id/resource_groups' do
          authorize! :read_resource_group, user_project

          present paginate(user_project.resource_groups), with: Entities::Ci::ResourceGroup
        end

        desc 'Get a specific resource group' do
          success Entities::Ci::ResourceGroup
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags ci_resource_groups_tags
        end
        params do
          requires :key, type: String, desc: 'The key of the resource group'
        end
        get ':id/resource_groups/:key', requirements: RESOURCE_GROUP_ENDPOINT_REQUIREMENTS do
          authorize! :read_resource_group, resource_group

          present resource_group, with: Entities::Ci::ResourceGroup
        end

        desc 'List upcoming jobs for a specific resource group' do
          success Entities::Ci::JobBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags ci_resource_groups_tags
        end
        params do
          requires :key, type: String, desc: 'The key of the resource group'

          use :pagination
        end
        get ':id/resource_groups/:key/upcoming_jobs', requirements: RESOURCE_GROUP_ENDPOINT_REQUIREMENTS do
          authorize! :read_resource_group, resource_group
          authorize! :read_build, user_project

          upcoming_processables = resource_group
            .upcoming_processables
            .preload(:user, pipeline: :project) # rubocop:disable CodeReuse/ActiveRecord

          present paginate(upcoming_processables), with: Entities::Ci::JobBasic
        end

        desc 'Edit an existing resource group' do
          detail "Updates an existing resource group's properties."
          success Entities::Ci::ResourceGroup
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags ci_resource_groups_tags
        end
        params do
          requires :key, type: String, desc: 'The key of the resource group'

          optional :process_mode,
            type: String,
            desc: 'The process mode of the resource group',
            values: ::Ci::ResourceGroup.process_modes.keys
        end
        put ':id/resource_groups/:key', requirements: RESOURCE_GROUP_ENDPOINT_REQUIREMENTS do
          authorize! :update_resource_group, resource_group

          if resource_group.update(declared_params(include_missing: false))
            present resource_group, with: Entities::Ci::ResourceGroup
          else
            render_validation_error!(resource_group)
          end
        end
      end

      helpers do
        def resource_group
          @resource_group ||= user_project.resource_groups.find_by_key!(params[:key])
        end
      end
    end
  end
end
