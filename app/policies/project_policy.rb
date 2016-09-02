class ProjectPolicy < BasePolicy
  def rules
    team_access!(user)

    owner = user.admin? ||
            project.owner == user ||
            (project.group && project.group.has_owner?(user))

    owner_access! if owner

    if project.public? || (project.internal? && !user.external?)
      guest_access!
      public_access!

      # Allow to read builds for internal projects
      can! :read_build if project.public_builds?

      if project.request_access_enabled &&
         !(owner || project.team.member?(user) || project_group_member?(user))
        can! :request_access
      end
    end

    archived_access! if project.archived?

    # EE-only
    can! :change_repository_storage if user.admin?

    disabled_features!
  end

  def project
    @subject
  end

  def guest_access!
    can! :read_project
    can! :read_board
    can! :read_list
    can! :read_wiki
    can! :read_issue
    can! :read_label
    can! :read_milestone
    can! :read_project_snippet
    can! :read_project_member
    can! :read_merge_request
    can! :read_note
    can! :create_project
    can! :create_issue
    can! :create_note
    can! :upload_file
  end

  def reporter_access!
    can! :download_code
    can! :fork_project
    can! :create_project_snippet
    can! :update_issue
    can! :admin_issue
    can! :admin_label
    can! :admin_list
    can! :read_commit_status
    can! :read_build
    can! :read_container_image
    can! :read_pipeline
    can! :read_environment
    can! :read_deployment
  end

  def developer_access!
    can! :admin_merge_request
    can! :update_merge_request
    can! :create_commit_status
    can! :update_commit_status
    can! :create_build
    can! :update_build
    can! :create_pipeline
    can! :update_pipeline
    can! :create_merge_request
    can! :create_wiki
    can! :push_code
    can! :resolve_note
    can! :create_container_image
    can! :update_container_image
    can! :create_environment
    can! :create_deployment
  end

  def master_access!
    can! :push_code_to_protected_branches
    can! :update_project_snippet
    can! :update_environment
    can! :update_deployment
    can! :admin_milestone
    can! :admin_project_snippet
    can! :admin_project_member
    can! :admin_merge_request
    can! :admin_note
    can! :admin_wiki
    can! :admin_project
    can! :admin_commit_status
    can! :admin_build
    can! :admin_container_image
    can! :admin_pipeline
    can! :admin_environment
    can! :admin_deployment

    # EE-only
    can! :admin_path_locks
    can! :admin_pages
    can! :read_pages
    can! :update_pages
  end

  def public_access!
    can! :download_code
    can! :fork_project
    can! :read_commit_status
    can! :read_pipeline
    can! :read_container_image
  end

  def owner_access!
    guest_access!
    reporter_access!
    developer_access!
    master_access!
    can! :change_namespace
    can! :change_visibility_level
    can! :rename_project
    can! :remove_project
    can! :archive_project
    can! :remove_fork_project
    can! :destroy_merge_request
    can! :destroy_issue

    # EE-only
    can! :remove_pages
  end

  # Push abilities on the users team role
  def team_access!(user)
    access = project.team.max_member_access(user.id)

    guest_access!     if access >= Gitlab::Access::GUEST
    reporter_access!  if access >= Gitlab::Access::REPORTER
    developer_access! if access >= Gitlab::Access::DEVELOPER
    master_access!    if access >= Gitlab::Access::MASTER
  end

  def archived_access!
    cannot! :create_merge_request
    cannot! :push_code
    cannot! :push_code_to_protected_branches
    cannot! :update_merge_request
    cannot! :admin_merge_request
  end

  def disabled_features!
    unless project.feature_available?(:issues, user)
      cannot!(*named_abilities(:issue))
    end

    unless project.feature_available?(:merge_requests, user)
      cannot!(*named_abilities(:merge_request))
    end

    unless project.feature_available?(:issues, user) || project.feature_available?(:merge_requests, user)
      cannot!(*named_abilities(:label))
      cannot!(*named_abilities(:milestone))
    end

    unless project.feature_available?(:snippets, user)
      cannot!(*named_abilities(:project_snippet))
    end

    unless project.feature_available?(:wiki, user) || project.has_external_wiki?
      cannot!(*named_abilities(:wiki))
    end

    unless project.feature_available?(:builds, user)
      cannot!(*named_abilities(:build))
      cannot!(*named_abilities(:pipeline))
      cannot!(*named_abilities(:environment))
      cannot!(*named_abilities(:deployment))
    end

    unless project.container_registry_enabled
      cannot!(*named_abilities(:container_image))
    end

    # EE-only
    if defined?(License) && License.block_changes?
      cannot! :create_issue
      cannot! :create_merge_request
      cannot! :push_code
      cannot! :push_code_to_protected_branches
    end
  end

  def anonymous_rules
    return unless project.public?

    can! :read_project
    can! :read_board
    can! :read_list
    can! :read_wiki
    can! :read_label
    can! :read_milestone
    can! :read_project_snippet
    can! :read_project_member
    can! :read_merge_request
    can! :read_note
    can! :read_pipeline
    can! :read_commit_status
    can! :read_container_image
    can! :download_code

    # NOTE: may be overridden by IssuePolicy
    can! :read_issue

    # Allow to read builds by anonymous user if guests are allowed
    can! :read_build if project.public_builds?

    disabled_features!
  end

  def project_group_member?(user)
    project.group &&
    (
      project.group.members.exists?(user_id: user.id) ||
      project.group.requesters.exists?(user_id: user.id)
    )
  end

  def named_abilities(name)
    [
      :"read_#{name}",
      :"create_#{name}",
      :"update_#{name}",
      :"admin_#{name}"
    ]
  end
end
