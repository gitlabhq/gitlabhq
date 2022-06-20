# frozen_string_literal: true

class GroupMember < Member
  extend ::Gitlab::Utils::Override
  include FromUnion
  include CreatedAtFilterable

  SOURCE_TYPE = 'Namespace'
  SOURCE_TYPE_FORMAT = /\ANamespace\z/.freeze
  THRESHOLD_FOR_REFRESHING_AUTHORIZATIONS_VIA_PROJECTS = 1000

  belongs_to :group, foreign_key: 'source_id'
  alias_attribute :namespace_id, :source_id
  delegate :update_two_factor_requirement, to: :user, allow_nil: true

  # Make sure group member points only to group as it source
  default_value_for :source_type, SOURCE_TYPE
  validates :source_type, format: { with: SOURCE_TYPE_FORMAT }

  default_scope { where(source_type: SOURCE_TYPE) } # rubocop:disable Cop/DefaultScope

  scope :of_groups, ->(groups) { where(source_id: groups&.select(:id)) }
  scope :of_ldap_type, -> { where(ldap: true) }
  scope :count_users_by_group_id, -> { group(:source_id).count }
  scope :with_user, -> (user) { where(user: user) }

  after_create :update_two_factor_requirement, unless: :invite?
  after_destroy :update_two_factor_requirement, unless: :invite?

  attr_accessor :last_owner, :last_blocked_owner

  # For those who get to see a modal with a role dropdown, here are the options presented
  def self.permissible_access_level_roles(_, _)
    # This method is a stopgap in preparation for https://gitlab.com/gitlab-org/gitlab/-/issues/364087
    access_level_roles
  end

  def self.access_level_roles
    Gitlab::Access.options_with_owner
  end

  def self.pluck_user_ids
    pluck(:user_id)
  end

  def group
    source
  end

  # Because source_type is `Namespace`...
  def real_source_type
    Group.sti_name
  end

  def notifiable_options
    { group: group }
  end

  private

  override :refresh_member_authorized_projects
  def refresh_member_authorized_projects(blocking:)
    # Here, `destroyed_by_association` will be present if the
    # GroupMember is being destroyed due to the `dependent: :destroy`
    # callback on Group. In this case, there is no need to refresh the
    # authorizations, because whenever a Group is being destroyed,
    # its projects are also destroyed, so the removal of project_authorizations
    # will happen behind the scenes via DB foreign keys anyway.
    return if destroyed_by_association.present?
    return unless user_id
    return super if Feature.disabled?(:refresh_authorizations_via_affected_projects_on_group_membership, group)

    # rubocop:disable CodeReuse/ServiceClass
    projects_to_refresh = Groups::ProjectsRequiringAuthorizationsRefresh::OnDirectMembershipFinder.new(group).execute
    threshold_exceeded = (projects_to_refresh.size > THRESHOLD_FOR_REFRESHING_AUTHORIZATIONS_VIA_PROJECTS)

    # We want to try the new approach only if the number of affected projects are greater than the set threshold.
    return super unless threshold_exceeded

    AuthorizedProjectUpdate::ProjectAccessChangedService
      .new(projects_to_refresh)
      .execute(blocking: false)

    # Until we compare the inconsistency rates of the new approach
    # the old approach, we still run AuthorizedProjectsWorker
    # but with some delay and lower urgency as a safety net.
    UserProjectAccessChangedService
      .new(user_id)
      .execute(blocking: false, priority: UserProjectAccessChangedService::LOW_PRIORITY)

    # rubocop:enable CodeReuse/ServiceClass
  end

  def send_invite
    run_after_commit_or_now { notification_service.invite_group_member(self, @raw_invite_token) }

    super
  end

  def post_create_hook
    if send_welcome_email?
      run_after_commit_or_now { notification_service.new_group_member(self) }
    end

    super
  end

  def post_update_hook
    if saved_change_to_access_level?
      run_after_commit { notification_service.update_group_member(self) }
    end

    if saved_change_to_expires_at?
      run_after_commit { notification_service.updated_group_member_expiration(self) }
    end

    super
  end

  def after_accept_invite
    run_after_commit_or_now do
      notification_service.accept_group_invite(self)
    end

    update_two_factor_requirement

    super
  end

  def after_decline_invite
    notification_service.decline_group_invite(self)

    super
  end

  def send_welcome_email?
    true
  end
end

GroupMember.prepend_mod_with('GroupMember')
