# frozen_string_literal: true

module API
  class Subscriptions < Grape::API
    before { authenticate! }

    subscribables = [
      { type: 'merge_requests', source: Project, finder: ->(id) { find_merge_request_with_access(id, :update_merge_request) }, parent_resource: -> { user_project } },
      { type: 'issues', source: Project, finder: ->(id) { find_project_issue(id) }, parent_resource: -> { user_project } },
      { type: 'labels', source: Project, finder: ->(id) { find_label(user_project, id) }, parent_resource: -> { user_project } },
      { type: 'labels', source: Group, finder: ->(id) { find_label(user_group, id) }, parent_resource: -> { nil } }
    ]

    subscribables.each do |subscribable|
      source_type = subscribable[:source].name.underscore
      entity_class = Entities.const_get(subscribable[:type].singularize.camelcase)

      params do
        requires :id, type: String, desc: "The #{source_type} ID"
        requires :subscribable_id, type: String, desc: 'The ID of a resource'
      end
      resource source_type.pluralize, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        desc 'Subscribe to a resource' do
          success entity_class
        end
        post ":id/#{subscribable[:type]}/:subscribable_id/subscribe" do
          parent = instance_exec(&subscribable[:parent_resource])
          resource = instance_exec(params[:subscribable_id], &subscribable[:finder])

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
        post ":id/#{subscribable[:type]}/:subscribable_id/unsubscribe" do
          parent = instance_exec(&subscribable[:parent_resource])
          resource = instance_exec(params[:subscribable_id], &subscribable[:finder])

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
