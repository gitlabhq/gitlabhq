module API
  class Subscriptions < Grape::API
    before { authenticate! }

    subscribables = [
      ['merge_requests', Project, proc { |id| find_merge_request_with_access(id, :update_merge_request) }, proc { user_project }],
      ['issues', Project, proc { |id| find_project_issue(id) }, proc { user_project }],
      ['labels', Project, proc { |id| find_label(user_project, id) }, proc { user_project }],
      ['labels', Group, proc { |id| find_label(user_group, id) }, proc { nil }]
    ]

    subscribables.each do |subscribable|
      type = subscribable[0]
      type_singularized = type.singularize
      source_type = subscribable[1].name.underscore
      finder = subscribable[2]
      parent_ressource = subscribable[3]
      entity_class = Entities.const_get(type_singularized.camelcase)

      params do
        requires :id, type: String, desc: "The #{source_type} ID"
        requires :subscribable_id, type: String, desc: 'The ID of a resource'
      end
      resource source_type.pluralize, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        desc 'Subscribe to a resource' do
          success entity_class
        end
        post ":id/#{type}/:subscribable_id/subscribe" do
          parent = instance_exec(&parent_ressource)
          resource = instance_exec(params[:subscribable_id], &finder)

          if resource.subscribed?(current_user, parent)
            not_modified!
          else
            resource.subscribe(current_user, parent)
            present resource, with: entity_class, current_user: current_user, project: parent
          end
        end

        desc 'Unsubscribe from a resource' do
          success entity_class
        end
        post ":id/#{type}/:subscribable_id/unsubscribe" do
          parent = instance_exec(&parent_ressource)
          resource = instance_exec(params[:subscribable_id], &finder)


          if !resource.subscribed?(current_user, parent)
            not_modified!
          else
            resource.unsubscribe(current_user, parent)
            present resource, with: entity_class, current_user: current_user, project: parent
          end
        end
      end
    end
  end
end
