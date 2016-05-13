module API
  class Subscriptions < Grape::API
    before { authenticate! }

    subscribable_types = {
      'merge_request' => proc { |id| user_project.merge_requests.find(id) },
      'merge_requests' => proc { |id| user_project.merge_requests.find(id) },
      'issues' => proc { |id| find_project_issue(id) },
      'labels' => proc { |id| find_project_label(id) },
    }

    resource :projects do
      subscribable_types.each do |type, finder|
        type_singularized = type.singularize
        type_id_str = :"#{type_singularized}_id"
        entity_class = Entities.const_get(type_singularized.camelcase)

        # Subscribe to a resource
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   subscribable_id (required) - The ID of a resource
        # Example Request:
        #   POST /projects/:id/labels/:subscribable_id/subscription
        #   POST /projects/:id/issues/:subscribable_id/subscription
        #   POST /projects/:id/merge_requests/:subscribable_id/subscription
        post ":id/#{type}/:#{type_id_str}/subscription" do
          resource = instance_exec(params[type_id_str], &finder)

          if resource.subscribed?(current_user)
            not_modified!
          else
            resource.subscribe(current_user)
            present resource, with: entity_class, current_user: current_user
          end
        end

        # Unsubscribe from a resource
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   subscribable_id (required) - The ID of a resource
        # Example Request:
        #   DELETE /projects/:id/labels/:subscribable_id/subscription
        #   DELETE /projects/:id/issues/:subscribable_id/subscription
        #   DELETE /projects/:id/merge_requests/:subscribable_id/subscription
        delete ":id/#{type}/:#{type_id_str}/subscription" do
          resource = instance_exec(params[type_id_str], &finder)

          if !resource.subscribed?(current_user)
            not_modified!
          else
            resource.unsubscribe(current_user)
            present resource, with: entity_class, current_user: current_user
          end
        end
      end
    end
  end
end
