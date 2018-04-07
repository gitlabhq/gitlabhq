class ProjectPolicy < BasePolicy
  prepend EE::ProjectPolicy

  def self.create_read_update_admin(name)
    [
      :"create_#{name}",
      :"read_#{name}",
      :"update_#{name}",
      :"admin_#{name}"
    ]
  end

  desc "User is a project owner"
  condition :owner do
    (project.owner.present? && project.owner == @user) ||
      project.group&.has_owner?(@user)
  end

  desc "Project has public builds enabled"
  condition(:public_builds, scope: :subject) { project.public_builds? }

  # For guest access we use #team_member? so we can use
  # project.members, which gets cached in subject scope.
  # This is safe because team_access_level is guaranteed
  # by ProjectAuthorization's validation to be at minimum
  # GUEST
  desc "User has guest access"
  condition(:guest) { team_member? }

  desc "User has reporter access"
  condition(:reporter) { team_access_level >= Gitlab::Access::REPORTER }

  desc "User has developer access"
  condition(:developer) { team_access_level >= Gitlab::Access::DEVELOPER }

  desc "User has master access"
  condition(:master) { team_access_level >= Gitlab::Access::MASTER }

  desc "Project is public"
  condition(:public_project, scope: :subject) { project.public? }

  desc "Project is visible to internal users"
  condition(:internal_access) do
    project.internal? && !user.external?
  end

  desc "User is a member of the group"
  condition(:group_member, scope: :subject) { project_group_member? }

  desc "Project is archived"
  condition(:archived, scope: :subject) { project.archived? }

  condition(:default_issues_tracker, scope: :subject) { project.default_issues_tracker? }

  desc "Container registry is disabled"
  condition(:container_registry_disabled, scope: :subject) do
    !project.container_registry_enabled
  end

  desc "Project has an external wiki"
  condition(:has_external_wiki, scope: :subject) { project.has_external_wiki? }

  desc "Project has request access enabled"
  condition(:request_access_enabled, scope: :subject) { project.request_access_enabled }

  desc "Has merge requests allowing pushes to user"
  condition(:has_merge_requests_allowing_pushes, scope: :subject) do
    project.merge_requests_allowing_push_to_user(user).any?
  end

  # We aren't checking `:read_issue` or `:read_merge_request` in this case
  # because it could be possible for a user to see an issuable-iid
  # (`:read_issue_iid` or `:read_merge_request_iid`) but then wouldn't be
  # allowed to read the actual issue after a more expensive `:read_issue`
  # check. These checks are intended to be used alongside
  # `:read_project_for_iids`.
  #
  # `:read_issue` & `:read_issue_iid` could diverge in gitlab-ee.
  condition(:issues_visible_to_user, score: 4) do
    @subject.feature_available?(:issues, @user)
  end

  condition(:merge_requests_visible_to_user, score: 4) do
    @subject.feature_available?(:merge_requests, @user)
  end

  features = %w[
    merge_requests
    issues
    repository
    snippets
    wiki
    builds
  ]

  features.each do |f|
    # these are scored high because they are unlikely
    desc "Project has #{f} disabled"
    condition(:"#{f}_disabled", score: 32) { !feature_available?(f.to_sym) }
  end

  # `:read_project` may be prevented in EE, but `:read_project_for_iids` should
  # not.
  rule { guest | admin }.enable :read_project_for_iids

  rule { guest }.enable :guest_access
  rule { reporter }.enable :reporter_access
  rule { developer }.enable :developer_access
  rule { master }.enable :master_access
  rule { owner | admin }.enable :owner_access

  rule { can?(:owner_access) }.policy do
    enable :guest_access
    enable :reporter_access
    enable :developer_access
    enable :master_access

    enable :change_namespace
    enable :change_visibility_level
    enable :rename_project
    enable :remove_project
    enable :archive_project
    enable :remove_fork_project
    enable :destroy_merge_request
    enable :destroy_issue
    enable :remove_pages
  end

  rule { can?(:guest_access) }.policy do
    enable :read_project
    enable :read_board
    enable :read_list
    enable :read_wiki
    enable :read_issue
    enable :read_label
    enable :read_milestone
    enable :read_project_snippet
    enable :read_project_member
    enable :read_note
    enable :create_project
    enable :create_issue
    enable :create_note
    enable :upload_file
    enable :read_cycle_analytics
  end

  # These abilities are not allowed to admins that are not members of the project,
  # that's why they are defined separately.
  rule { guest & can?(:download_code) }.enable :build_download_code
  rule { guest & can?(:read_container_image) }.enable :build_read_container_image

  rule { can?(:reporter_access) }.policy do
    enable :download_code
    enable :download_wiki_code
    enable :fork_project
    enable :create_project_snippet
    enable :update_issue
    enable :admin_issue
    enable :admin_label
    enable :admin_list
    enable :read_commit_status
    enable :read_build
    enable :read_container_image
    enable :read_pipeline
    enable :read_pipeline_schedule
    enable :read_environment
    enable :read_deployment
    enable :read_merge_request
  end

  # We define `:public_user_access` separately because there are cases in gitlab-ee
  # where we enable or prevent it based on other coditions.
  rule { (~anonymous & public_project) | internal_access }.policy do
    enable :public_user_access
    enable :read_project_for_iids
  end

  rule { can?(:public_user_access) }.policy do
    enable :public_access
    enable :guest_access

    enable :fork_project
    enable :build_download_code
    enable :build_read_container_image
    enable :request_access
  end

  rule { owner | admin | guest | group_member }.prevent :request_access
  rule { ~request_access_enabled }.prevent :request_access

  rule { can?(:developer_access) }.policy do
    enable :admin_merge_request
    enable :admin_milestone
    enable :update_merge_request
    enable :create_commit_status
    enable :update_commit_status
    enable :create_build
    enable :update_build
    enable :create_pipeline
    enable :update_pipeline
    enable :create_pipeline_schedule
    enable :create_merge_request
    enable :create_wiki
    enable :push_code
    enable :resolve_note
    enable :create_container_image
    enable :update_container_image
    enable :create_environment
    enable :create_deployment
  end

  rule { can?(:master_access) }.policy do
    enable :delete_protected_branch
    enable :update_project_snippet
    enable :update_environment
    enable :update_deployment
    enable :admin_project_snippet
    enable :admin_project_member
    enable :admin_note
    enable :admin_wiki
    enable :admin_project
    enable :admin_commit_status
    enable :admin_build
    enable :admin_container_image
    enable :admin_pipeline
    enable :admin_environment
    enable :admin_deployment
    enable :admin_pages
    enable :read_pages
    enable :update_pages
    enable :read_cluster
    enable :create_cluster
  end

  rule { archived }.policy do
    prevent :create_merge_request
    prevent :push_code
    prevent :delete_protected_branch
    prevent :update_merge_request
    prevent :admin_merge_request
  end

  rule { merge_requests_disabled | repository_disabled }.policy do
    prevent(*create_read_update_admin(:merge_request))
  end

  rule { issues_disabled & merge_requests_disabled }.policy do
    prevent(*create_read_update_admin(:label))
    prevent(*create_read_update_admin(:milestone))
  end

  rule { snippets_disabled }.policy do
    prevent(*create_read_update_admin(:project_snippet))
  end

  rule { wiki_disabled & ~has_external_wiki }.policy do
    prevent(*create_read_update_admin(:wiki))
    prevent(:download_wiki_code)
  end

  rule { builds_disabled | repository_disabled }.policy do
    prevent(*create_read_update_admin(:build))
    prevent(*(create_read_update_admin(:pipeline) - [:read_pipeline]))
    prevent(*create_read_update_admin(:pipeline_schedule))
    prevent(*create_read_update_admin(:environment))
    prevent(*create_read_update_admin(:deployment))
  end

  rule { repository_disabled }.policy do
    prevent :push_code
    prevent :download_code
    prevent :fork_project
    prevent :read_commit_status
  end

  rule { container_registry_disabled }.policy do
    prevent(*create_read_update_admin(:container_image))
  end

  rule { anonymous & ~public_project }.prevent_all

  rule { public_project }.policy do
    enable :public_access
    enable :read_project_for_iids
  end

  rule { can?(:public_access) }.policy do
    enable :read_project
    enable :read_board
    enable :read_list
    enable :read_wiki
    enable :read_label
    enable :read_milestone
    enable :read_project_snippet
    enable :read_project_member
    enable :read_merge_request
    enable :read_note
    enable :read_pipeline
    enable :read_pipeline_schedule
    enable :read_commit_status
    enable :read_container_image
    enable :download_code
    enable :download_wiki_code
    enable :read_cycle_analytics

    # NOTE: may be overridden by IssuePolicy
    enable :read_issue
  end

  rule { public_builds }.policy do
    enable :read_build
  end

  rule { public_builds & can?(:guest_access) }.policy do
    enable :read_pipeline
    enable :read_pipeline_schedule
  end

  rule { issues_disabled }.policy do
    prevent :create_issue
    prevent :update_issue
    prevent :admin_issue
    prevent :read_issue
  end

  # These rules are included to allow maintainers of projects to push to certain
  # to run pipelines for the branches they have access to.
  rule { can?(:public_access) & has_merge_requests_allowing_pushes }.policy do
    enable :create_build
    enable :update_build
    enable :create_pipeline
    enable :update_pipeline
  end

  rule do
    (can?(:read_project_for_iids) & issues_visible_to_user) | can?(:read_issue)
  end.enable :read_issue_iid

  rule do
    (can?(:read_project_for_iids) & merge_requests_visible_to_user) | can?(:read_merge_request)
  end.enable :read_merge_request_iid

  private

  def team_member?
    return false if @user.nil?

    greedy_load_subject = false

    # when scoping by subject, we want to be greedy
    # and load *all* the members with one query.
    greedy_load_subject ||= DeclarativePolicy.preferred_scope == :subject

    # in this case we're likely to have loaded #members already
    # anyways, and #member? would fail with an error
    greedy_load_subject ||= !@user.persisted?

    if greedy_load_subject
      project.team.members.include?(user)
    else
      # otherwise we just make a specific query for
      # this particular user.
      team_access_level >= Gitlab::Access::GUEST
    end
  end

  def project_group_member?
    return false if @user.nil?

    project.group &&
      (
        project.group.members_with_parents.exists?(user_id: @user.id) ||
        project.group.requesters.exists?(user_id: @user.id)
      )
  end

  def team_access_level
    return -1 if @user.nil?

    # NOTE: max_member_access has its own cache
    project.team.max_member_access(@user.id)
  end

  def feature_available?(feature)
    case project.project_feature.access_level(feature)
    when ProjectFeature::DISABLED
      false
    when ProjectFeature::PRIVATE
      guest? || admin?
    else
      true
    end
  end

  def project
    @subject
  end
end
