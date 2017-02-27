module API
  module V3
    class Subscriptions < Grape::API
      before { authenticate! }

      subscribable_types = {
        'merge_request' => proc { |id| find_merge_request_with_access(id, :update_merge_request) },
        'merge_requests' => proc { |id| find_merge_request_with_access(id, :update_merge_request) },
        'issues' => proc { |id| find_project_issue(id) },
        'labels' => proc { |id| find_project_label(id) },
      }

      params do
        requires :id, type: String, desc: 'The ID of a project'
        requires :subscribable_id, type: String, desc: 'The ID of a resource'
      end
      resource :projects do
        subscribable_types.each do |type, finder|
          type_singularized = type.singularize
          entity_class = ::API::Entities.const_get(type_singularized.camelcase)

          desc 'Subscribe to a resource' do
            success entity_class
          end
          post ":id/#{type}/:subscribable_id/subscription" do
            resource = instance_exec(params[:subscribable_id], &finder)

            if resource.subscribed?(current_user, user_project)
              not_modified!
            else
              resource.subscribe(current_user, user_project)
              present resource, with: entity_class, current_user: current_user, project: user_project
            end
          end

          desc 'Unsubscribe from a resource' do
            success entity_class
          end
          delete ":id/#{type}/:subscribable_id/subscription" do
            resource = instance_exec(params[:subscribable_id], &finder)

            if !resource.subscribed?(current_user, user_project)
              not_modified!
            else
              resource.unsubscribe(current_user, user_project)
              present resource, with: entity_class, current_user: current_user, project: user_project
            end
          end
        end
      end
    end
  end
end
