# frozen_string_literal: true

module API
  class Subscriptions < ::API::Base
    helpers ::API::Helpers::LabelHelpers

    before { authenticate! }

    SUBSCRIBE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(
      subscribable_id: API::NO_SLASH_URL_PART_REGEX)

    subscribables = [
      {
        type: 'merge_requests',
        human_type: 'merge request',
        article: 'a',
        entity: Entities::MergeRequest,
        source: Project,
        finder: ->(id) { find_merge_request_with_access(id, :update_merge_request) },
        feature_category: :code_review_workflow
      },
      {
        type: 'issues',
        human_type: 'issue',
        article: 'an',
        entity: Entities::Issue,
        source: Project,
        finder: ->(id) { find_project_issue(id) },
        feature_category: :team_planning
      },
      {
        type: 'labels',
        human_type: 'project label',
        article: 'a',
        entity: Entities::ProjectLabel,
        source: Project,
        finder: ->(id) { find_label(user_project, id) },
        feature_category: :team_planning
      },
      {
        type: 'labels',
        human_type: 'group label',
        article: 'a',
        entity: Entities::GroupLabel,
        source: Group,
        finder: ->(id) { find_label(user_group, id) },
        feature_category: :team_planning
      }
    ]

    subscribables.each do |subscribable|
      source_type = subscribable[:source].name.underscore
      subscribable_type = subscribable[:human_type]
      subscribable_article = subscribable[:article]

      params do
        requires :id, type: String, desc: "The #{source_type} ID"
        requires :subscribable_id, type: String, desc: 'The ID of a resource'
      end
      resource source_type.pluralize, requirements: SUBSCRIBE_ENDPOINT_REQUIREMENTS do
        desc "Subscribe to #{subscribable_article} #{subscribable_type}" do
          detail "Subscribes the currently authenticated user to a specified #{subscribable_type}. They will " \
            "receive notifications on changes to this item."
          success subscribable[:entity]
          tags ['resource_subscriptions']
        end
        post ":id/#{subscribable[:type]}/:subscribable_id/subscribe", subscribable.slice(:feature_category) do
          parent = parent_resource(source_type)
          resource = instance_exec(params[:subscribable_id], &subscribable[:finder])

          if resource.subscribed?(current_user, parent)
            not_modified!
          else
            resource.subscribe(current_user, parent)
            present resource, with: subscribable[:entity], current_user: current_user, project: parent, parent: parent
          end
        end

        desc "Unsubscribe to #{subscribable_article} #{subscribable_type}" do
          detail "Unsubscribes the currently authenticated user from a specified #{subscribable_type}. They will no " \
            "longer receive notifications on changes to this item."
          success subscribable[:entity]
          tags ['resource_subscriptions']
        end
        post ":id/#{subscribable[:type]}/:subscribable_id/unsubscribe", subscribable.slice(:feature_category) do
          parent = parent_resource(source_type)
          resource = instance_exec(params[:subscribable_id], &subscribable[:finder])

          if !resource.subscribed?(current_user, parent)
            not_modified!
          else
            resource.unsubscribe(current_user, parent)
            present resource, with: subscribable[:entity], current_user: current_user, project: parent, parent: parent
          end
        end
      end
    end

    private

    helpers do
      def parent_resource(source_type)
        case source_type
        when 'project'
          user_project
        end
      end
    end
  end
end
