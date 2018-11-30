# frozen_string_literal: true

class IssuableSidebarEntity < Grape::Entity
  include RequestAwareEntity

  with_options if: { include_basic: true } do
    expose :id
    expose :type do |issuable|
      issuable.to_ability_name
    end
    expose :author_id
    expose :project_id do |issuable|
      issuable.project.id
    end
    expose :discussion_locked
    expose :reference do |issuable|
      issuable.to_reference(issuable.project, full: true)
    end

    expose :current_user, using: UserEntity do |issuable|
      request.current_user
    end

    # Relationships
    expose :todo, using: IssuableSidebarTodoEntity do |issuable|
      request.current_user.pending_todo_for(issuable) if request.current_user
    end
    expose :milestone, using: ::API::Entities::Milestone
    expose :labels, using: LabelEntity

    # Permissions
    expose :signed_in do |issuable|
      request.current_user.present?
    end

    expose :can_edit do |issuable|
      can?(request.current_user, :"admin_#{issuable.to_ability_name}", issuable.project)
    end

    expose :can_move do |issuable|
      request.current_user && issuable.can_move?(request.current_user)
    end

    expose :can_admin_label do |issuable|
      can?(request.current_user, :admin_label, issuable.project)
    end

    # Paths
    expose :issuable_json_path do |issuable|
      if issuable.is_a?(MergeRequest)
        project_merge_request_path(issuable.project, issuable.iid, :json)
      else
        project_issue_path(issuable.project, issuable.iid, :json)
      end
    end

    expose :namespace_path do |issuable|
      issuable.project.namespace.full_path
    end

    expose :project_path do |issuable|
      issuable.project.path
    end

    expose :project_full_path do |issuable|
      issuable.project.full_path
    end

    expose :project_issuables_path do |issuable|
      project = issuable.project
      namespace = project.namespace

      if issuable.is_a?(MergeRequest)
        namespace_project_merge_requests_path(namespace, project)
      else
        namespace_project_issues_path(namespace, project)
      end
    end

    expose :create_todo_path do |issuable|
      project_todos_path(issuable.project)
    end

    expose :project_milestones_path do |issuable|
      project_milestones_path(issuable.project, :json)
    end

    expose :project_labels_path do |issuable|
      project_labels_path(issuable.project, :json, include_ancestor_groups: true)
    end

    expose :toggle_subscription_path do |issuable|
      toggle_subscription_path(issuable)
    end

    expose :move_issue_path do |issuable|
      move_namespace_project_issue_path(
        namespace_id: issuable.project.namespace.to_param,
        project_id: issuable.project,
        id: issuable
      )
    end

    expose :projects_autocomplete_path do |issuable|
      autocomplete_projects_path(project_id: issuable.project.id)
    end
  end

  with_options if: { include_extras: true } do
    include TimeTrackableEntity

    expose :participants, using: ::API::Entities::UserBasic do |issuable|
      issuable.participants(request.current_user)
    end

    expose :subscribed do |issuable|
      issuable.subscribed?(request.current_user, issuable.project)
    end
  end
end
