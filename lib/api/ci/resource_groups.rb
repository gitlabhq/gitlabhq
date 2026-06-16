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
        desc 'List all resource groups' do
          detail 'Lists all resource groups for a specified project.'
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
        route_setting :authorization, permissions: :read_resource_group, boundary_type: :project
        get ':id/resource_groups' do
          authorize! :read_resource_group, user_project

          present paginate(user_project.resource_groups), with: Entities::Ci::ResourceGroup
        end

        desc 'Retrieve a resource group' do
          detail 'Retrieves a specified resource group for a project.'
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
        route_setting :authorization, permissions: :read_resource_group, boundary_type: :project
        get ':id/resource_groups/:key', requirements: RESOURCE_GROUP_ENDPOINT_REQUIREMENTS do
          authorize! :read_resource_group, resource_group

          present resource_group, with: Entities::Ci::ResourceGroup
        end

        desc 'Retrieve current job for a resource group' do
          detail 'Retrieves the current job for a specified resource group in a project.'
          success Entities::Ci::JobBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags ci_resource_groups_tags
        end
        params do
          requires :key, type: String, desc: 'The key of the resource group'
        end
        route_setting :authorization, permissions: [:read_resource_group, :read_job], boundary_type: :project
        get ':id/resource_groups/:key/current_job', requirements: RESOURCE_GROUP_ENDPOINT_REQUIREMENTS do
          authorize! :read_resource_group, resource_group
          authorize! :read_build, user_project

          current_processable = resource_group
            .current_processable

          present current_processable, with: Entities::Ci::JobBasic
        end

        desc 'List all upcoming jobs for a resource group' do
          detail 'Lists all upcoming jobs for a specified resource group.'
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
        route_setting :authorization, permissions: [:read_resource_group, :read_job], boundary_type: :project
        get ':id/resource_groups/:key/upcoming_jobs', requirements: RESOURCE_GROUP_ENDPOINT_REQUIREMENTS do
          authorize! :read_resource_group, resource_group
          authorize! :read_build, user_project

          upcoming_processables = resource_group
            .upcoming_processables
            .preload(:user, pipeline: :project) # rubocop:disable CodeReuse/ActiveRecord

          present paginate(upcoming_processables), with: Entities::Ci::JobBasic
        end

        desc 'Update a resource group' do
          detail 'Updates the properties for a specified resource group. It returns `200` if the resource group was ' \
            'successfully updated. In case of an error, a status code `400` is returned.'
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
        route_setting :authorization, permissions: :update_resource_group, boundary_type: :project
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
