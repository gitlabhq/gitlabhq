# frozen_string_literal: true

module API
  module Ci
    class ResourceGroups < ::API::Base
      before { authenticate! }

      feature_category :continuous_delivery

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get a single resource group' do
          success Entities::Ci::ResourceGroup
        end
        params do
          requires :key, type: String, desc: 'The key of the resource group'
        end
        get ':id/resource_groups/:key' do
          authorize! :read_resource_group, resource_group

          present resource_group, with: Entities::Ci::ResourceGroup
        end

        desc 'Edit a resource group' do
          success Entities::Ci::ResourceGroup
        end
        params do
          requires :key, type: String, desc: 'The key of the resource group'
          optional :process_mode, type: String, desc: 'The process mode',
                                  values: ::Ci::ResourceGroup.process_modes.keys
        end
        put ':id/resource_groups/:key' do
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
