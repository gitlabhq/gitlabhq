module API
  class Subscriptions < Grape::API
    before { authenticate! }

    subscribable_types = {
      'merge_request' => proc { |id| user_project.merge_requests.find(id) },
      'merge_requests' => proc { |id| user_project.merge_requests.find(id) },
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
        entity_class = Entities.const_get(type_singularized.camelcase)

        desc 'Subscribe to a resource' do
          success entity_class
        end
        post ":id/#{type}/:subscribable_id/subscription" do
          resource = instance_exec(params[:subscribable_id], &finder)

          if resource.subscribed?(current_user)
            not_modified!
          else
            resource.subscribe(current_user)
            present resource, with: entity_class, current_user: current_user
          end
        end

        desc 'Unsubscribe from a resource' do
          success entity_class
        end
        delete ":id/#{type}/:subscribable_id/subscription" do
          resource = instance_exec(params[:subscribable_id], &finder)

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
