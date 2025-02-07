# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class User < ApplicationRecord
  extend Gitlab::ConfigHelper

  include Gitlab::ConfigHelper
  include Gitlab::SQL::Pattern
  include AfterCommitQueue
  include Avatarable
  include Referable
  include Sortable
  include CaseSensitivity
  include TokenAuthenticatable
  include FeatureGate
  include CreatedAtFilterable
  include BulkMemberAccessLoad
  include BlocksUnsafeSerialization
  include WithUploads
  include OptionallySearch
  include FromUnion
  include BatchDestroyDependentAssociations
  include BatchNullifyDependentAssociations
  include UpdateHighestRole
  include HasUserType
  include Gitlab::Auth::Otp::Fortinet
  include Gitlab::Auth::Otp::DuoAuth
  include RestrictedSignup
  include StripAttribute
  include EachBatch
  include IgnorableColumns
  include CrossDatabaseIgnoredTables
  include UseSqlFunctionForPrimaryKeyLookups
  include Todoable

  # `ensure_namespace_correct` needs to be moved to an after_commit (?)
  cross_database_ignore_tables %w[namespaces namespace_settings], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424279'

  # `notification_settings_for` is called, and elsewhere `save` is then called.
  cross_database_ignore_tables %w[notification_settings], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424284'

  # Associations with dependent: option
  cross_database_ignore_tables(
    %w[namespaces projects project_authorizations issues merge_requests merge_requests issues issues merge_requests events],
    url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424285',
    on: :destroy
  )

  ignore_column :last_access_from_pipl_country_at, remove_after: '2024-11-17', remove_with: '17.7'

  DEFAULT_NOTIFICATION_LEVEL = :participating

  INSTANCE_ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT = 10

  BLOCKED_PENDING_APPROVAL_STATE = 'blocked_pending_approval'

  COUNT_CACHE_VALIDITY_PERIOD = 24.hours

  OTP_SECRET_LENGTH = 32
  OTP_SECRET_TTL = 2.minutes

  MAX_USERNAME_LENGTH = 255
  MIN_USERNAME_LENGTH = 2

  MAX_LIMIT_FOR_ASSIGNEED_ISSUES_COUNT = 100

  SECONDARY_EMAIL_ATTRIBUTES = [
    :commit_email,
    :notification_email,
    :public_email
  ].freeze

  FORBIDDEN_SEARCH_STATES = %w[blocked banned ldap_blocked].freeze

  INCOMING_MAIL_TOKEN_PREFIX = 'glimt-'
  FEED_TOKEN_PREFIX = 'glft-'

  FIRST_GROUP_PATHS_LIMIT = 200

  SERVICE_ACCOUNT_PREFIX = 'service_account'
  NOREPLY_EMAIL_DOMAIN = "noreply.#{Gitlab.config.gitlab.host}".freeze

  # lib/tasks/tokens.rake needs to be updated when changing mail and feed tokens
  add_authentication_token_field :incoming_email_token, token_generator: -> { self.generate_incoming_mail_token } # rubocop:disable Gitlab/TokenWithoutPrefix -- wontfix: the prefix is in the generator
  add_authentication_token_field :feed_token, format_with_prefix: :prefix_for_feed_token
  # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/439294
  add_authentication_token_field :static_object_token, encrypted: :optional # rubocop:todo Gitlab/TokenWithoutPrefix -- https://gitlab.com/gitlab-org/gitlab/-/issues/439294

  attribute :admin, default: false
  attribute :external, default: -> { Gitlab::CurrentSettings.user_default_external }
  attribute :can_create_group, default: -> { Gitlab::CurrentSettings.can_create_group }
  attribute :private_profile, default: -> { Gitlab::CurrentSettings.user_defaults_to_private_profile }
  attribute :can_create_team, default: false
  attribute :hide_no_ssh_key, default: false
  attribute :hide_no_password, default: false
  attribute :project_view, default: :files
  attribute :notified_of_own_activity, default: false
  attribute :preferred_language, default: -> { Gitlab::CurrentSettings.default_preferred_language }
  attribute :theme_id, default: -> { gitlab_config.default_theme }
  attribute :color_scheme_id, default: -> { Gitlab::CurrentSettings.default_syntax_highlighting_theme }
  attribute :color_mode_id, default: -> { Gitlab::ColorModes::APPLICATION_DEFAULT }

  attr_encrypted :otp_secret,
    key: Gitlab::Application.credentials.otp_key_base,
    mode: :per_attribute_iv_and_salt,
    insecure_mode: true,
    algorithm: 'aes-256-cbc'

  devise :two_factor_authenticatable,
    otp_secret_encryption_key: Gitlab::Application.credentials.otp_key_base

  devise :two_factor_backupable, otp_number_of_backup_codes: 10
  devise :two_factor_backupable_pbkdf2
  serialize :otp_backup_codes, JSON # rubocop:disable Cop/ActiveRecordSerialize

  devise :lockable, :recoverable, :rememberable, :trackable,
    :validatable, :omniauthable, :confirmable, :registerable

  # Must be included after `devise`
  include EncryptedUserPassword
  include RecoverableByAnyEmail

  include AdminChangedPasswordNotifier

  # This module adds async behaviour to Devise emails
  # and should be added after Devise modules are initialized.
  include AsyncDeviseEmail
  include ForcedEmailConfirmation
  include RequireEmailVerification

  MINIMUM_DAYS_CREATED = 7

  # Override Devise::Models::Trackable#update_tracked_fields!
  # to limit database writes to at most once every hour
  # rubocop: disable CodeReuse/ServiceClass
  def update_tracked_fields!(request)
    return if Gitlab::Database.read_only?

    update_tracked_fields(request)

    Gitlab::ExclusiveLease.throttle(id) do
      ::Ability.forgetting(/admin/) do
        Users::UpdateService.new(self, user: self).execute(validate: false)
      end
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  # Virtual attribute for impersonator
  attr_accessor :impersonator

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace,
    -> { where(type: Namespaces::UserNamespace.sti_name) },
    required: false,
    dependent: :destroy, # rubocop:disable Cop/ActiveRecordDependent
    foreign_key: :owner_id,
    inverse_of: :owner,
    autosave: true

  # Profile
  has_many :keys, -> { regular_keys }, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :expired_today_and_unnotified_keys, -> { expired_today_and_not_notified }, class_name: 'Key'
  has_many :expiring_soon_and_unnotified_keys, -> { expiring_soon_and_not_notified }, class_name: 'Key'
  has_many :deploy_keys, -> { where(type: 'DeployKey') }, dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :group_deploy_keys
  has_many :gpg_keys

  has_many :emails
  has_many :personal_access_tokens, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :expiring_soon_and_unnotified_personal_access_tokens, -> { expiring_and_not_notified_without_impersonation }, class_name: 'PersonalAccessToken'

  has_many :identities, dependent: :destroy, autosave: true # rubocop:disable Cop/ActiveRecordDependent
  has_many :webauthn_registrations
  has_many :chat_names, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :saved_replies, class_name: '::Users::SavedReply'
  has_one :user_synced_attributes_metadata, autosave: true
  has_one :aws_role, class_name: 'Aws::Role'

  # Ghost User Migration
  has_one :ghost_user_migration, class_name: 'Users::GhostUserMigration'

  # Followers
  has_many :followed_users, foreign_key: :follower_id, class_name: 'Users::UserFollowUser'
  has_many :followees, -> { active }, through: :followed_users

  has_many :following_users, foreign_key: :followee_id, class_name: 'Users::UserFollowUser'
  has_many :followers, -> { active }, through: :following_users

  # Namespaces
  has_many :members
  has_many :member_namespaces, through: :members

  # Groups
  has_many :group_members, -> { where(requested_at: nil).where("access_level >= ?", Gitlab::Access::GUEST) }, class_name: 'GroupMember'
  has_many :groups, through: :group_members
  has_many :groups_with_active_memberships, -> { where(members: { state: ::Member::STATE_ACTIVE }) }, through: :group_members, source: :group
  has_many :owned_groups, -> { where(members: { access_level: Gitlab::Access::OWNER }) }, through: :group_members, source: :group
  has_many :maintainers_groups, -> { where(members: { access_level: Gitlab::Access::MAINTAINER }) }, through: :group_members, source: :group
  has_many :developer_groups, -> { where(members: { access_level: ::Gitlab::Access::DEVELOPER }) }, through: :group_members, source: :group
  has_many :owned_or_maintainers_groups,
    -> { where(members: { access_level: [Gitlab::Access::MAINTAINER, Gitlab::Access::OWNER] }) },
    through: :group_members,
    source: :group
  alias_attribute :masters_groups, :maintainers_groups
  has_many :developer_maintainer_owned_groups,
    -> { where(members: { access_level: [Gitlab::Access::DEVELOPER, Gitlab::Access::MAINTAINER, Gitlab::Access::OWNER] }) },
    through: :group_members,
    source: :group
  has_many :reporter_developer_maintainer_owned_groups,
    -> { where(members: { access_level: [Gitlab::Access::REPORTER, Gitlab::Access::DEVELOPER, Gitlab::Access::MAINTAINER, Gitlab::Access::OWNER] }) },
    through: :group_members,
    source: :group
  has_many :minimal_access_group_members, -> { where(access_level: [Gitlab::Access::MINIMAL_ACCESS]) }, class_name: 'GroupMember'
  has_many :minimal_access_groups, through: :minimal_access_group_members, source: :group

  # Projects
  has_many :groups_projects,          through: :groups, source: :projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :project_members, -> { where(requested_at: nil) }
  has_many :projects,                 through: :project_members
  has_many :created_projects,         foreign_key: :creator_id, class_name: 'Project', dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :created_namespace_details, foreign_key: :creator_id, class_name: 'Namespace::Detail'
  has_many :projects_with_active_memberships, -> { where(members: { state: ::Member::STATE_ACTIVE }) }, through: :project_members, source: :project
  has_many :users_star_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :starred_projects, through: :users_star_projects, source: :project
  has_many :project_authorizations, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :authorized_projects, through: :project_authorizations, source: :project

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :legacy_assigned_merge_requests, class_name: 'MergeRequest', dependent: :nullify, foreign_key: :assignee_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :merged_merge_requests, class_name: 'MergeRequest::Metrics', dependent: :nullify, foreign_key: :merged_by_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :closed_merge_requests, class_name: 'MergeRequest::Metrics', dependent: :nullify, foreign_key: :latest_closed_by_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :updated_merge_requests, class_name: 'MergeRequest', dependent: :nullify, foreign_key: :updated_by_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :updated_issues, class_name: 'Issue', dependent: :nullify, foreign_key: :updated_by_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :closed_issues, class_name: 'Issue', dependent: :nullify, foreign_key: :closed_by_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :events,                   dependent: :delete_all, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :releases,                 dependent: :nullify, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :subscriptions,            dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :abuse_reports, dependent: :nullify, foreign_key: :user_id, inverse_of: :user # rubocop:disable Cop/ActiveRecordDependent
  has_many :admin_abuse_report_assignees, class_name: "Admin::AbuseReportAssignee"
  has_many :assigned_abuse_reports, class_name: "AbuseReport", through: :admin_abuse_report_assignees, source: :abuse_report
  has_many :reported_abuse_reports,   dependent: :nullify, foreign_key: :reporter_id, class_name: "AbuseReport", inverse_of: :reporter # rubocop:disable Cop/ActiveRecordDependent
  has_many :resolved_abuse_reports,   foreign_key: :resolved_by_id, class_name: "AbuseReport", inverse_of: :resolved_by
  has_many :abuse_events,             foreign_key: :user_id, class_name: 'AntiAbuse::Event', inverse_of: :user
  has_many :spam_logs,                dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :abuse_trust_scores,       class_name: 'AntiAbuse::TrustScore', foreign_key: :user_id
  has_many :builds,                   class_name: 'Ci::Build'
  has_many :pipelines,                class_name: 'Ci::Pipeline'
  has_many :todos,                    dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :authored_todos, class_name: 'Todo', dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :notification_settings
  has_many :award_emoji, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :triggers, -> { Feature.enabled?(:trigger_token_expiration) ? not_expired : self }, class_name: 'Ci::Trigger', foreign_key: :owner_id
  has_many :audit_events, foreign_key: :author_id, inverse_of: :user
  has_many :uploaded_uploads, class_name: 'Upload', foreign_key: :uploaded_by_user_id

  has_many :alert_assignees, class_name: '::AlertManagement::AlertAssignee', inverse_of: :assignee
  has_many :issue_assignees, inverse_of: :assignee
  has_many :merge_request_assignees, inverse_of: :assignee, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :merge_request_reviewers, inverse_of: :reviewer, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :assigned_issues, class_name: "Issue", through: :issue_assignees, source: :issue
  has_many :assigned_merge_requests, class_name: "MergeRequest", through: :merge_request_assignees, source: :merge_request
  has_many :created_custom_emoji, class_name: 'CustomEmoji', inverse_of: :creator

  has_many :bulk_imports
  has_one :namespace_import_user, class_name: 'Import::NamespaceImportUser', inverse_of: :import_user

  has_many :custom_attributes, class_name: 'UserCustomAttribute'
  has_one  :trusted_with_spam_attribute, -> { UserCustomAttribute.trusted_with_spam }, class_name: 'UserCustomAttribute'
  has_many :callouts, class_name: 'Users::Callout'
  has_many :group_callouts, class_name: 'Users::GroupCallout'
  has_many :project_callouts, class_name: 'Users::ProjectCallout'
  has_many :term_agreements
  belongs_to :accepted_term, class_name: 'ApplicationSetting::Term'
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :organization_users, class_name: 'Organizations::OrganizationUser', inverse_of: :user

  has_many :organizations, through: :organization_users, class_name: 'Organizations::Organization', inverse_of: :users,
    disable_joins: true
  has_many :owned_organizations, -> { where(organization_users: { access_level: Gitlab::Access::OWNER }) },
    through: :organization_users, source: :organization, class_name: 'Organizations::Organization'

  has_one :status, class_name: 'UserStatus'
  has_one :user_preference
  has_one :user_detail
  has_one :user_highest_role
  has_one :credit_card_validation, class_name: '::Users::CreditCardValidation'
  has_one :phone_number_validation, class_name: '::Users::PhoneNumberValidation'
  has_one :atlassian_identity, class_name: 'Atlassian::Identity'
  has_one :banned_user, class_name: '::Users::BannedUser'

  has_many :reviews, foreign_key: :author_id, inverse_of: :author

  has_many :timelogs

  has_many :resource_label_events, dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :resource_state_events, dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :issue_assignment_events, class_name: 'ResourceEvents::IssueAssignmentEvent', dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :merge_request_assignment_events, class_name: 'ResourceEvents::MergeRequestAssignmentEvent', dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :authored_events, class_name: 'Event', dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :early_access_program_tracking_events, class_name: 'EarlyAccessProgram::TrackingEvent', inverse_of: :user
  has_many :namespace_commit_emails, class_name: 'Users::NamespaceCommitEmail'
  has_many :user_achievements, class_name: 'Achievements::UserAchievement', inverse_of: :user
  has_many :awarded_user_achievements, class_name: 'Achievements::UserAchievement', foreign_key: 'awarded_by_user_id', inverse_of: :awarded_by_user
  has_many :revoked_user_achievements, class_name: 'Achievements::UserAchievement', foreign_key: 'revoked_by_user_id', inverse_of: :revoked_by_user
  has_many :achievements, through: :user_achievements, class_name: 'Achievements::Achievement', inverse_of: :users
  has_many :vscode_settings, class_name: 'VsCode::Settings::VsCodeSetting', inverse_of: :user

  has_many :requested_member_approvals, class_name: 'Members::MemberApproval', foreign_key: 'requested_by_id'
  has_many :reviewed_member_approvals, class_name: 'Members::MemberApproval', foreign_key: 'reviewed_by_id'

  has_many :broadcast_message_dismissals, class_name: 'Users::BroadcastMessageDismissal'

  #
  # Validations
  #
  # Note: devise :validatable above adds validations for :email and :password
  validates :username,
    presence: true,
    exclusion: { in: Gitlab::PathRegex::TOP_LEVEL_ROUTES, message: N_('%{value} is a reserved name') }
  validates :username, uniqueness: true, unless: :namespace
  validate :username_not_assigned_to_pages_unique_domain, if: :username_changed?
  validates :name, presence: true, length: { maximum: 255 }
  validates :first_name, length: { maximum: 127 }
  validates :last_name, length: { maximum: 127 }
  validates :email, confirmation: true, devise_email: true
  validates :notification_email, devise_email: true, allow_blank: true
  validates :public_email, uniqueness: true, devise_email: true, allow_blank: true
  validates :commit_email, devise_email: true, allow_blank: true, unless: ->(user) { user.commit_email == Gitlab::PrivateCommitEmail::TOKEN }
  validates :projects_limit,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: Gitlab::Database::MAX_INT_VALUE }
  validate  :check_password_weakness, if: :encrypted_password_changed?

  validates :namespace, presence: true, unless: :optional_namespace?
  validate :namespace_move_dir_allowed, if: :username_changed?, unless: :new_record?

  validate :unique_email, if: :email_changed?
  validates_with AntiAbuse::UniqueDetumbledEmailValidator, if: :email_changed?
  validate :notification_email_verified, if: :notification_email_changed?
  validate :public_email_verified, if: :public_email_changed?
  validate :commit_email_verified, if: :commit_email_changed?
  validate :email_allowed_by_restrictions, if: ->(user) { user.new_record? ? !user.created_by_id : user.email_changed? }
  validate :check_username_format, if: :username_changed?

  validates :theme_id, allow_nil: true, inclusion: { in: Gitlab::Themes.valid_ids,
                                                     message: ->(*) { _("%{placeholder} is not a valid theme") % { placeholder: '%{value}' } } }
  validates :color_mode_id, allow_nil: true, inclusion: { in: Gitlab::ColorModes.valid_ids,
                                                          message: ->(*) { _("%{placeholder} is not a valid color mode") % { placeholder: '%{value}' } } }
  validates :color_scheme_id, allow_nil: true, inclusion: { in: Gitlab::ColorSchemes.valid_ids,
                                                            message: ->(*) { _("%{placeholder} is not a valid color scheme") % { placeholder: '%{value}' } } }
  validates :hide_no_ssh_key, allow_nil: false, inclusion: { in: [true, false] }
  validates :hide_no_password, allow_nil: false, inclusion: { in: [true, false] }
  validates :notified_of_own_activity, allow_nil: false, inclusion: { in: [true, false] }
  validates :project_view, presence: true
  validates :composite_identity_enforced, inclusion: { in: [false] }, unless: -> { service_account? }

  after_initialize :set_projects_limit
  # Ensures we get a user_detail on all new user records.
  # We are not able to fully guard against all possible places where User.new
  # is created, so we rely on the callback here at the model layer for our best
  # chance at ensuring the user_detail is created.
  # However, we need to skip all non-new records as after_initialize is called on basic finders as well.
  after_initialize :build_default_user_detail, if: :new_record?
  before_validation :sanitize_attrs
  before_validation :ensure_namespace_correct
  after_validation :set_username_errors
  before_save :ensure_incoming_email_token
  before_save :ensure_user_rights_and_limits, if: ->(user) { user.new_record? || user.external_changed? }
  before_save :skip_reconfirmation!, if: ->(user) { user.email_changed? && user.read_only_attribute?(:email) }
  before_save :check_for_verified_email, if: ->(user) { user.email_changed? && !user.new_record? }
  before_save :ensure_namespace_correct # in case validation is skipped
  after_update :username_changed_hook, if: :saved_change_to_username?
  after_destroy :post_destroy_hook
  after_destroy :remove_key_cache
  after_save if: -> { (saved_change_to_email? || saved_change_to_confirmed_at?) && confirmed? } do
    email_to_confirm = self.emails.find_by(email: self.email)

    if email_to_confirm.present?
      if skip_confirmation_period_expiry_check
        email_to_confirm.force_confirm
      else
        email_to_confirm.confirm
      end
    else
      ignore_cross_database_tables_if_factory_bot(%w[emails]) do
        add_primary_email_to_emails!
      end
    end
  end
  after_commit(on: :update) do
    update_invalid_gpg_signatures if previous_changes.key?('email')
  end

  # User's Layout preference
  enum layout: { fixed: 0, fluid: 1 }

  # User's Dashboard preference
  enum dashboard: {
    projects: 0,
    stars: 1,
    member_projects: 11,
    your_activity: 10,
    project_activity: 2,
    starred_project_activity: 3,
    groups: 4,
    todos: 5,
    issues: 6,
    merge_requests: 7,
    operations: 8,
    followed_user_activity: 9
  }

  # User's Project preference
  enum project_view: { readme: 0, activity: 1, files: 2, wiki: 3 }

  # User's role
  enum role: { software_developer: 0, development_team_lead: 1, devops_engineer: 2, systems_administrator: 3, security_analyst: 4, data_analyst: 5, product_manager: 6, product_designer: 7, other: 8 }, _suffix: true

  delegate :notes_filter_for,
    :set_notes_filter,
    :first_day_of_week, :first_day_of_week=,
    :timezone, :timezone=,
    :time_display_relative, :time_display_relative=,
    :time_display_format, :time_display_format=,
    :show_whitespace_in_diffs, :show_whitespace_in_diffs=,
    :view_diffs_file_by_file, :view_diffs_file_by_file=,
    :pass_user_identities_to_ci_jwt, :pass_user_identities_to_ci_jwt=,
    :tab_width, :tab_width=,
    :sourcegraph_enabled, :sourcegraph_enabled=,
    :gitpod_enabled, :gitpod_enabled=,
    :extensions_marketplace_opt_in_status, :extensions_marketplace_opt_in_status=,
    :organization_groups_projects_sort, :organization_groups_projects_sort=,
    :organization_groups_projects_display, :organization_groups_projects_display=,
    :extensions_marketplace_enabled, :extensions_marketplace_enabled=,
    :setup_for_company, :setup_for_company=,
    :project_shortcut_buttons, :project_shortcut_buttons=,
    :keyboard_shortcuts_enabled, :keyboard_shortcuts_enabled=,
    :render_whitespace_in_code, :render_whitespace_in_code=,
    :markdown_surround_selection, :markdown_surround_selection=,
    :markdown_automatic_lists, :markdown_automatic_lists=,
    :diffs_deletion_color, :diffs_deletion_color=,
    :diffs_addition_color, :diffs_addition_color=,
    :use_new_navigation, :use_new_navigation=,
    :pinned_nav_items, :pinned_nav_items=,
    :achievements_enabled, :achievements_enabled=,
    :enabled_following, :enabled_following=,
    :home_organization, :home_organization_id, :home_organization_id=,
    :dpop_enabled, :dpop_enabled=,
    :use_work_items_view, :use_work_items_view=,
    :text_editor, :text_editor=,
    :default_text_editor_enabled, :default_text_editor_enabled=,
    to: :user_preference

  delegate :path, to: :namespace, allow_nil: true, prefix: true
  delegate :job_title, :job_title=, to: :user_detail, allow_nil: true
  delegate :bio, :bio=, to: :user_detail, allow_nil: true
  delegate :webauthn_xid, :webauthn_xid=, to: :user_detail, allow_nil: true
  delegate :pronouns, :pronouns=, to: :user_detail, allow_nil: true
  delegate :pronunciation, :pronunciation=, to: :user_detail, allow_nil: true
  delegate :registration_objective, :registration_objective=, to: :user_detail, allow_nil: true
  delegate :bluesky, :bluesky=, to: :user_detail, allow_nil: true
  delegate :mastodon, :mastodon=, to: :user_detail, allow_nil: true
  delegate :linkedin, :linkedin=, to: :user_detail, allow_nil: true
  delegate :twitter, :twitter=, to: :user_detail, allow_nil: true
  delegate :skype, :skype=, to: :user_detail, allow_nil: true
  delegate :website_url, :website_url=, to: :user_detail, allow_nil: true
  delegate :location, :location=, to: :user_detail, allow_nil: true
  delegate :organization, :organization=, to: :user_detail, allow_nil: true
  delegate :discord, :discord=, to: :user_detail, allow_nil: true
  delegate :email_reset_offered_at, :email_reset_offered_at=, to: :user_detail, allow_nil: true
  delegate :project_authorizations_recalculated_at, :project_authorizations_recalculated_at=, to: :user_detail, allow_nil: true
  delegate :bot_namespace, :bot_namespace=, to: :user_detail, allow_nil: true

  accepts_nested_attributes_for :user_preference, update_only: true
  accepts_nested_attributes_for :user_detail, update_only: true
  accepts_nested_attributes_for :credit_card_validation, update_only: true, allow_destroy: true
  accepts_nested_attributes_for :organization_users, update_only: true

  state_machine :state, initial: :active do
    # state_machine uses this method at class loading time to fetch the default
    # value for the `state` column but in doing so it also evaluates all other
    # columns default values which could trigger the recursive generation of
    # ApplicationSetting records. We're setting it to `nil` here because we
    # don't have a database default for the `state` column.
    #
    def owner_class_attribute_default; end

    event :block do
      transition active: :blocked
      transition deactivated: :blocked
      transition ldap_blocked: :blocked
      transition blocked_pending_approval: :blocked
    end

    event :ldap_block do
      transition active: :ldap_blocked
      transition deactivated: :ldap_blocked
    end

    # aliasing system_block to set ldap_blocked statuses
    # ldap_blocked is used for LDAP, SAML, and SCIM blocked users
    # Issue for improving this naming:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/388487
    event :system_block do
      transition active: :ldap_blocked
      transition deactivated: :ldap_blocked
    end

    event :activate do
      transition deactivated: :active
      transition blocked: :active
      transition ldap_blocked: :active
      transition blocked_pending_approval: :active
      transition banned: :active
    end

    event :block_pending_approval do
      transition active: :blocked_pending_approval
    end

    event :ban do
      transition active: :banned
    end

    event :unban do
      transition banned: :active
    end

    event :deactivate do
      # Any additional changes to this event should be also
      # reflected in app/workers/users/deactivate_dormant_users_worker.rb
      transition active: :deactivated
    end

    state :blocked, :ldap_blocked, :blocked_pending_approval, :banned do
      def blocked?
        true
      end
    end

    before_transition do
      !Gitlab::Database.read_only?
    end

    # rubocop: disable CodeReuse/ServiceClass
    after_transition any => :blocked do |user|
      user.run_after_commit do
        Ci::DropPipelinesAndDisableSchedulesForUserService.new.execute(
          user,
          reason: :user_blocked,
          include_owned_projects_and_groups: false
        )
      end
    end

    after_transition any => :deactivated do |user|
      next unless Gitlab::CurrentSettings.user_deactivation_emails_enabled

      user.run_after_commit do
        NotificationService.new.user_deactivated(user.name, user.notification_email_or_default)
      end
    end

    after_transition active: :banned do |user|
      user.create_banned_user

      user.invalidate_authored_todo_user_pending_todo_cache_counts

      if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- this is always necessary on GitLab.com
        user.run_after_commit do
          deep_clean_ci = user.custom_attributes.by_key(UserCustomAttribute::DEEP_CLEAN_CI_USAGE_WHEN_BANNED).exists?

          Ci::DropPipelinesAndDisableSchedulesForUserService.new.execute(
            user,
            reason: :user_banned,
            include_owned_projects_and_groups: deep_clean_ci
          )
        end
      end
    end
    # rubocop: enable CodeReuse/ServiceClass

    after_transition banned: :active do |user|
      user.banned_user&.destroy
      user.invalidate_authored_todo_user_pending_todo_cache_counts
    end

    after_transition any => :active do |user|
      user.class.temporary_ignore_cross_database_tables(
        %w[projects], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424278'
      ) do
        user.starred_projects.update_counters(star_count: 1)
      end
    end

    after_transition active: any do |user|
      user.class.temporary_ignore_cross_database_tables(
        %w[projects], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424278'
      ) do
        user.starred_projects.update_counters(star_count: -1)
      end
    end
  end

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :instance_access_request_approvers_to_be_notified, -> { admins.active.order_recent_sign_in.limit(INSTANCE_ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT) }
  scope :blocked, -> { with_states(:blocked, :ldap_blocked) }
  scope :blocked_pending_approval, -> { with_states(:blocked_pending_approval) }
  scope :banned, -> { with_states(:banned) }
  scope :external, -> { where(external: true) }
  scope :non_external, -> { where(external: false) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :active, -> { with_state(:active).non_internal }
  scope :without_active, -> { without_state(:active) }
  scope :active_without_ghosts, -> { with_state(:active).without_ghosts }
  scope :all_without_ghosts, -> { without_ghosts }
  scope :deactivated, -> { with_state(:deactivated).non_internal }
  scope :without_projects, -> do
    joins('LEFT JOIN project_authorizations ON users.id = project_authorizations.user_id')
    .where(project_authorizations: { user_id: nil })
    .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422045')
  end
  scope :by_username, ->(usernames) { iwhere(username: Array(usernames).map(&:to_s)) }
  scope :by_name, ->(names) { iwhere(name: Array(names)) }
  scope :by_login, ->(login) do
    return none if login.blank?

    login.include?('@') ? iwhere(email: login) : iwhere(username: login)
  end
  scope :by_user_email, ->(emails) { iwhere(email: Array(emails)) }
  scope :by_emails, ->(emails) { joins(:emails).where(emails: { email: Array(emails).map(&:downcase) }) }
  scope :by_detumbled_emails, ->(detumbled_emails) do
    joins(:emails).where(emails: { detumbled_email: Array(detumbled_emails) })
  end
  scope :for_todos, ->(todos) { where(id: todos.select(:user_id).distinct) }
  scope :with_emails, -> { preload(:emails) }
  scope :with_dashboard, ->(dashboard) { where(dashboard: dashboard) }
  scope :with_public_profile, -> { where(private_profile: false) }
  scope :with_personal_access_tokens_expired_today, -> do
    where('EXISTS (?)', ::PersonalAccessToken
      .select(1)
      .where('personal_access_tokens.user_id = users.id')
      .without_impersonation
      .expired_today_and_not_notified
    )
  end

  scope :with_ssh_key_expiring_soon, -> do
    includes(:expiring_soon_and_unnotified_keys)
      .where('EXISTS (?)', ::Key
        .select(1)
        .where('keys.user_id = users.id')
        .expiring_soon_and_not_notified)
  end

  scope :with_personal_access_tokens_expiring_soon, -> do
    includes(:expiring_soon_and_unnotified_personal_access_tokens)
  end

  scope :order_recent_sign_in, -> { reorder(arel_table[:current_sign_in_at].desc.nulls_last) }
  scope :order_oldest_sign_in, -> { reorder(arel_table[:current_sign_in_at].asc.nulls_last) }
  scope :order_recent_last_activity, -> { reorder(arel_table[:last_activity_on].desc.nulls_last, arel_table[:id].asc) }
  scope :order_oldest_last_activity, -> { reorder(arel_table[:last_activity_on].asc.nulls_first, arel_table[:id].desc) }
  scope :ordered_by_id_desc, -> { reorder(arel_table[:id].desc) }
  scope :ordered_by_name_asc_id_desc, -> { order(name: :asc, id: :desc) }

  scope :dormant, -> { with_state(:active).human_or_service_user.where('last_activity_on <= ?', Gitlab::CurrentSettings.deactivate_dormant_users_period.day.ago.to_date) }
  scope :with_no_activity, -> { with_state(:active).human_or_service_user.where(last_activity_on: nil).where('created_at <= ?', MINIMUM_DAYS_CREATED.day.ago.to_date) }
  scope :by_provider_and_extern_uid, ->(provider, extern_uid) { joins(:identities).merge(Identity.with_extern_uid(provider, extern_uid)) }
  scope :by_ids, ->(ids) { where(id: ids) }
  scope :by_ids_or_usernames, ->(ids, usernames) { where(username: usernames).or(where(id: ids)) }
  scope :without_forbidden_states, -> { where.not(state: FORBIDDEN_SEARCH_STATES) }
  scope :trusted, -> do
    where('EXISTS (?)', ::UserCustomAttribute
      .select(1)
      .where('user_id = users.id')
      .trusted_with_spam)
  end

  # This scope to be used only for bot_users since for
  # regular users this may lead to memory allocation issues
  scope :with_personal_access_tokens_and_resources, -> do
    includes(:personal_access_tokens)
    .includes(:groups)
    .includes(:projects)
  end

  scope :left_join_user_detail, -> { left_joins(:user_detail) }
  scope :preload_user_detail, -> { preload(:user_detail) }

  scope :by_bot_namespace_ids, ->(namespace_ids) do
    project_bot.joins(:user_detail).where(user_detail: { bot_namespace_id: namespace_ids })
  end

  def self.supported_keyset_orderings
    {
      id: [:asc, :desc],
      name: [:asc, :desc],
      username: [:asc, :desc],
      created_at: [:asc, :desc],
      updated_at: [:asc, :desc]
    }
  end

  strip_attributes! :name

  def preferred_language
    read_attribute('preferred_language').presence || Gitlab::CurrentSettings.default_preferred_language
  end

  def active_for_authentication?
    return false unless super

    check_ldap_if_ldap_blocked!

    can?(:log_in)
  end

  # The messages for these keys are defined in `devise.en.yml`
  def inactive_message
    if blocked_pending_approval?
      :blocked_pending_approval
    elsif blocked?
      :blocked
    elsif internal?
      :forbidden
    else
      super
    end
  end

  def self.with_visible_profile(user)
    return with_public_profile if user.nil?

    if user.admin?
      all
    else
      with_public_profile.or(where(id: user.id))
    end
  end

  # Limits the users to those that have TODOs, optionally in the given state.
  #
  # user - The user to get the todos for.
  #
  # with_todos - If we should limit the result set to users that are the
  #              authors of todos.
  #
  # todo_state - An optional state to require the todos to be in.
  def self.limit_to_todo_authors(user: nil, with_todos: false, todo_state: nil)
    if user && with_todos
      where(id: Todo.where(user: user, state: todo_state).select(:author_id))
    else
      all
    end
  end

  # Returns a relation that optionally includes the given user.
  #
  # user_id - The ID of the user to include.
  def self.union_with_user(user_id = nil)
    if user_id.present?
      # We use "unscoped" here so that any inner conditions are not repeated for
      # the outer query, which would be redundant.
      User.unscoped.from_union([all, User.unscoped.where(id: user_id)])
    else
      all
    end
  end

  def self.with_two_factor
    where(otp_required_for_login: true)
      .or(where_exists(WebauthnRegistration.where(WebauthnRegistration.arel_table[:user_id].eq(arel_table[:id]))))
  end

  def self.without_two_factor
    where
      .missing(:webauthn_registrations)
      .where(otp_required_for_login: false)
  end

  #
  # Class methods
  #
  class << self
    # Devise method overridden to allow support for dynamic password lengths
    def password_length
      Gitlab::CurrentSettings.minimum_password_length..Devise.password_length.max
    end

    # Generate a random password that conforms to the current password length settings
    def random_password
      Devise.friendly_token(password_length.max)
    end

    # Devise method overridden to allow sign in with email or username
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).find_by("lower(username) = :value OR lower(email) = :value", value: login.downcase.strip)
      else
        find_by(conditions)
      end
    end

    def sort_by_attribute(method)
      order_method = method || 'id_desc'

      case order_method.to_s
      when 'recent_sign_in' then order_recent_sign_in
      when 'oldest_sign_in' then order_oldest_sign_in
      when 'last_activity_on_desc' then order_recent_last_activity
      when 'last_activity_on_asc' then order_oldest_last_activity
      else
        order_by(order_method)
      end
    end

    # Find a User by their primary email or any associated confirmed secondary email
    def find_by_any_email(email, confirmed: false)
      return unless email

      by_any_email(email, confirmed: confirmed).take
    end

    # Returns a relation containing all found users by their primary email
    # or any associated confirmed secondary email
    #
    # @param emails [String, Array<String>] email addresses to check
    # @param confirmed [Boolean] Only return users where the primary email is confirmed
    def by_any_email(emails, confirmed: false)
      return none if Array(emails).all?(&:nil?)

      from_users = by_user_email(emails)
      from_users = from_users.confirmed if confirmed

      from_emails = by_emails(emails).merge(Email.confirmed)
      from_emails = from_emails.confirmed if confirmed

      items = [from_users, from_emails]

      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/461885
      # What about private commit emails with capitalized username, we'd never find them and
      # since the private_commit_email derives from the username, it can
      # be uppercase in parts. So we'll never find an existing user during the invite
      # process by email if that is true as we are case sensitive in this case.
      user_ids = Gitlab::PrivateCommitEmail.user_ids_for_emails(Array(emails).map(&:downcase))
      items << where(id: user_ids) if user_ids.present?

      from_union(items)
    end

    def find_by_private_commit_email(email)
      user_id = Gitlab::PrivateCommitEmail.user_id_for_email(email)

      find_by(id: user_id)
    end

    def filter_items(filter_name)
      case filter_name
      when 'admins'
        admins
      when 'blocked'
        blocked
      when 'blocked_pending_approval'
        blocked_pending_approval
      when 'banned'
        banned
      when 'two_factor_disabled'
        without_two_factor
      when 'two_factor_enabled'
        with_two_factor
      when 'wop'
        without_projects
      when 'external'
        external
      when 'deactivated'
        deactivated
      when "trusted"
        trusted
      when "active"
        active_without_ghosts
      else
        all_without_ghosts
      end
    end

    # Searches users matching the given query.
    #
    # This method uses ILIKE on PostgreSQL.
    #
    # query - The search query as a String
    # with_private_emails - include private emails in search
    # partial_email_search - only for admins to preserve email privacy. Only for self-managed instances.
    #
    # Returns an ActiveRecord::Relation.
    def search(query, **options)
      return none unless query.is_a?(String)

      query = query&.delete_prefix('@')
      return none if query.blank?

      query = query.downcase

      order = <<~SQL
        CASE
          WHEN LOWER(users.public_email) = :query THEN 0
          WHEN LOWER(users.username) = :query THEN 1
          WHEN LOWER(users.name) = :query THEN 2
          ELSE 3
        END
      SQL

      sanitized_order_sql = Arel.sql(sanitize_sql_array([order, { query: query }]))

      use_minimum_char_limit = options[:use_minimum_char_limit]

      scope =
        if options[:with_private_emails]
          with_primary_or_secondary_email(
            query, use_minimum_char_limit: use_minimum_char_limit, partial_email_search: options[:partial_email_search]
          )
        else
          with_public_email(query)
        end

      scope = scope.or(search_by_name_or_username(query, use_minimum_char_limit: use_minimum_char_limit))

      order = Gitlab::Pagination::Keyset::Order.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'users_match_priority',
            order_expression: sanitized_order_sql.asc,
            add_to_projections: true
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'users_name',
            order_expression: arel_table[:name].asc,
            add_to_projections: true,
            nullable: :not_nullable
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'users_id',
            order_expression: arel_table[:id].asc,
            add_to_projections: true,
            nullable: :not_nullable
          )
        ])
      scope.reorder(order)
    end

    # This should be kept in sync with the frontend filtering in
    # https://gitlab.com/gitlab-org/gitlab/-/blob/5d34e3488faa3982d30d7207773991c1e0b6368a/app/assets/javascripts/gfm_auto_complete.js#L68 and
    # https://gitlab.com/gitlab-org/gitlab/-/blob/5d34e3488faa3982d30d7207773991c1e0b6368a/app/assets/javascripts/gfm_auto_complete.js#L1053
    def gfm_autocomplete_search(query)
      where(
        "REPLACE(users.name, ' ', '') ILIKE :pattern OR users.username ILIKE :pattern",
        pattern: "%#{sanitize_sql_like(query)}%"
      ).order(
        Arel.sql(sanitize_sql(
          [
            "CASE WHEN REPLACE(users.name, ' ', '') ILIKE :prefix_pattern OR users.username ILIKE :prefix_pattern THEN 1 ELSE 2 END",
            { prefix_pattern: "#{sanitize_sql_like(query)}%" }
          ]
        )),
        :username,
        :id
      )
    end

    # Limits the result set to users _not_ in the given query/list of IDs.
    #
    # users - The list of users to ignore. This can be an
    #         `ActiveRecord::Relation`, or an Array.
    def where_not_in(users = nil)
      users ? where.not(id: users) : all
    end

    def reorder_by_name
      reorder(:name)
    end

    # searches user by given pattern
    # it compares name and username fields with given pattern
    # This method uses ILIKE on PostgreSQL.
    def search_by_name_or_username(query, use_minimum_char_limit: nil)
      use_minimum_char_limit = user_search_minimum_char_limit if use_minimum_char_limit.nil?

      where(
        fuzzy_arel_match(:name, query, use_minimum_char_limit: use_minimum_char_limit)
          .or(fuzzy_arel_match(:username, query, use_minimum_char_limit: use_minimum_char_limit))
      )
    end

    def with_public_email(email_address)
      where(public_email: email_address)
    end

    def with_primary_or_secondary_email(query, use_minimum_char_limit: true, partial_email_search: false)
      email_table = Email.arel_table

      if partial_email_search
        email_table_matched_by_email = Email.fuzzy_arel_match(:email, query, use_minimum_char_limit: use_minimum_char_limit)
        matched_by_email = User.fuzzy_arel_match(:email, query, use_minimum_char_limit: use_minimum_char_limit)
      else
        email_table_matched_by_email = email_table[:email].eq(query)
        matched_by_email = arel_table[:email].eq(query)
      end

      matched_by_email_user_id = email_table
        .project(email_table[:user_id])
        .where(email_table_matched_by_email)
        .where(email_table[:confirmed_at].not_eq(nil))
        .take(1) # at most 1 record as there is a unique constraint

      where(
        matched_by_email
        .or(arel_table[:id].eq(matched_by_email_user_id))
      )
    end

    # This method is overridden in JiHu.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/348509
    def user_search_minimum_char_limit
      true
    end

    def find_by_login(login)
      by_login(login).take
    end

    def find_by_username(username)
      by_username(username).take
    end

    def find_by_username!(username)
      by_username(username).take!
    end

    # Returns a user for the given SSH key. Deploy keys are excluded.
    def find_by_ssh_key_id(key_id)
      find_by('EXISTS (?)', Key.select(1).where('keys.user_id = users.id').auth.regular_keys.where(id: key_id))
    end

    def find_by_full_path(path, follow_redirects: false)
      namespace = Namespace.user_namespaces.find_by_full_path(path, follow_redirects: follow_redirects)
      namespace&.owner
    end

    def reference_prefix
      '@'
    end

    # Pattern used to extract `@user` user references from text
    def reference_pattern
      @reference_pattern ||=
        %r{
          (?<!\w)
          #{Regexp.escape(reference_prefix)}
          (?<user>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
        }x
    end

    # Return true if there is only single non-internal user in the deployment,
    # ghost user is ignored.
    def single_user?
      User.non_internal.limit(2).count == 1
    end

    def single_user
      User.non_internal.first if single_user?
    end

    def get_ids_by_ids_or_usernames(ids, usernames)
      by_ids_or_usernames(ids, usernames).pluck(:id)
    end

    def generate_incoming_mail_token
      "#{INCOMING_MAIL_TOKEN_PREFIX}#{SecureRandom.hex.to_i(16).to_s(36)}"
    end

    def username_exists?(username)
      exists?(username: username)
    end

    def ends_with_reserved_file_extension?(username)
      Mime::EXTENSION_LOOKUP.keys.any? { |type| username.end_with?(".#{type}") }
    end
  end

  #
  # Instance methods
  #

  def full_path
    username
  end

  def to_param
    username
  end

  def build_default_user_detail
    # We will need to ensure we keep checking to see if it exists logic since this runs from
    # an after_initialize.
    # In cases where user_detail params are added during a `User.new` or create call with user_detail
    # attributes set through delegation of setters, we will already have some user_detail
    # attributes created from a built user_detail that will then be removed by an
    # initialization of a new user_detail.
    # We can see one case of that in the Users::BuildService where it assigns user attributes that can
    # have delegated user_detail attributes added by classes that inherit this class and add
    # to the user attributes hash.
    # Therefore, we need to check for presence of an existing built user_detail here.
    user_detail || build_user_detail
  end

  def to_reference(_from = nil, target_container: nil, full: nil)
    "#{self.class.reference_prefix}#{username}"
  end

  def readable_by?(user)
    id == user.id
  end

  def skip_confirmation=(bool)
    skip_confirmation! if bool
  end

  def skip_reconfirmation=(bool)
    skip_reconfirmation! if bool
  end

  def generate_reset_token
    @reset_token, enc = Devise.token_generator.generate(self.class, :reset_password_token)

    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.current.utc

    @reset_token
  end

  def recently_sent_password_reset?
    reset_password_sent_at.present? && reset_password_sent_at >= 1.minute.ago
  end

  # Overwrites valid_password? from Devise::Models::DatabaseAuthenticatable
  # In constant-time, check both that the password isn't on a denylist AND
  # that the password is the user's password
  def valid_password?(password)
    return false unless password_allowed?(password)
    return false if password_automatically_set?
    return false unless allow_password_authentication?

    super
  end

  def generate_otp_backup_codes!
    if Gitlab::FIPS.enabled?
      generate_otp_backup_codes_pbkdf2!
    else
      super
    end
  end

  def invalidate_otp_backup_code!(code)
    if Gitlab::FIPS.enabled? && pbkdf2?
      invalidate_otp_backup_code_pdkdf2!(code)
    else
      super(code)
    end
  end

  # See https://gitlab.com/gitlab-org/security/gitlab/-/issues/638
  DISALLOWED_PASSWORDS = %w[123qweQWE!@#000000000].freeze

  def password_allowed?(password)
    password_allowed = true

    DISALLOWED_PASSWORDS.each do |disallowed_password|
      password_allowed = false if Devise.secure_compare(password, disallowed_password)
    end

    password_allowed
  end

  # Override Devise Rememberable#remember_me!
  #
  # In Devise this method sets `remember_created_at` and writes the session token
  # to the session cookie. When remember me is disabled this method ensures these
  # values aren't set.
  def remember_me!
    super if ::Gitlab::Database.read_write? && ::Gitlab::CurrentSettings.remember_me_enabled?
  end

  def forget_me!
    super if ::Gitlab::Database.read_write?
  end

  # Override Devise Rememberable#remember_me?
  #
  # In Devise this method compares the remember me token received from the user session
  # and compares to the stored value. When remember me is disabled this method ensures
  # the upstream comparison does not happen.
  def remember_me?(token, generated_at)
    return false unless ::Gitlab::CurrentSettings.remember_me_enabled?

    super
  end

  def disable_two_factor!
    transaction do
      self.disable_webauthn!
      self.disable_two_factor_otp!
      self.reset_backup_codes!
    end
  end

  def disable_two_factor_otp!
    update!(
      otp_required_for_login: false,
      encrypted_otp_secret: nil,
      encrypted_otp_secret_iv: nil,
      encrypted_otp_secret_salt: nil,
      otp_grace_period_started_at: nil,
      otp_secret_expires_at: nil
    )
  end

  def disable_webauthn!
    self.webauthn_registrations.destroy_all # rubocop:disable Cop/DestroyAll
  end

  def reset_backup_codes!
    update(otp_backup_codes: nil)
  end

  def two_factor_enabled?
    two_factor_otp_enabled? || two_factor_webauthn_enabled?
  end

  def two_factor_otp_enabled?
    otp_required_for_login? ||
      forti_authenticator_enabled?(self) ||
      forti_token_cloud_enabled?(self) ||
      duo_auth_enabled?(self)
  end

  def two_factor_webauthn_enabled?
    (webauthn_registrations.loaded? && webauthn_registrations.any?) || (!webauthn_registrations.loaded? && webauthn_registrations.exists?)
  end

  def needs_new_otp_secret?
    !two_factor_otp_enabled? && otp_secret_expired?
  end

  def otp_secret_expired?
    return true unless otp_secret_expires_at

    otp_secret_expires_at.past?
  end

  def update_otp_secret!
    self.otp_secret = User.generate_otp_secret(OTP_SECRET_LENGTH)
    self.otp_secret_expires_at = Time.current + OTP_SECRET_TTL
  end

  def namespace_move_dir_allowed
    if namespace&.any_project_has_container_registry_tags?
      errors.add(:username, _('cannot be changed if a personal project has container registry tags.'))
    end
  end

  # will_save_change_to_attribute? is used by Devise to check if it is necessary
  # to clear any existing reset_password_tokens before updating an authentication_key
  # and login in our case is a virtual attribute to allow login by username or email.
  def will_save_change_to_login?
    will_save_change_to_username? || will_save_change_to_email?
  end

  def unique_email
    email_taken = errors.added?(:email, _('has already been taken'))

    if !email_taken && Email.where.not(user: self).where(email: email).exists?
      errors.add(:email, _('has already been taken'))
      email_taken = true
    end

    if email_taken &&
        ::Feature.enabled?(:delay_delete_own_user) &&
        User.find_by_any_email(email)&.deleted_own_account?

      help_page_url = Rails.application.routes.url_helpers.help_page_url(
        'user/profile/account/delete_account.md',
        anchor: 'delete-your-own-account'
      )

      errors.add(:email, _('is linked to an account pending deletion.'), help_page_url: help_page_url)
    end
  end

  def commit_email_or_default
    if self.commit_email == Gitlab::PrivateCommitEmail::TOKEN
      return private_commit_email
    end

    # The commit email is the same as the primary email if undefined
    self.commit_email.presence || self.email
  end

  def notification_email_or_default
    # The notification email is the same as the primary email if undefined
    self.notification_email.presence || self.email
  end

  def private_commit_email
    Gitlab::PrivateCommitEmail.for_user(self)
  end

  # see if the new email is already a verified secondary email
  def check_for_verified_email
    skip_reconfirmation! if emails.confirmed.where(email: self.email).any?
  end

  def update_invalid_gpg_signatures
    gpg_keys.each(&:update_invalid_gpg_signatures)
  end

  # Returns the groups a user has access to, either through direct or inherited membership or a project authorization
  def authorized_groups
    Group.unscoped do
      direct_groups_cte = Gitlab::SQL::CTE.new(:direct_groups, groups)
      direct_groups_cte_alias = direct_groups_cte.table.alias(Group.table_name)

      groups_from_authorized_projects = Group.id_in(authorized_projects.select(:namespace_id)).self_and_ancestors
      groups_from_shares = Group.joins(:shared_with_group_links)
                             .where(group_group_links: { shared_with_group_id: Group.from(direct_groups_cte_alias) })
                             .self_and_descendants

      Group
        .with(direct_groups_cte.to_arel)
        .from_union([
          Group.from(direct_groups_cte_alias).self_and_descendants,
          groups_from_authorized_projects,
          groups_from_shares
        ])
    end
  end

  # Used to search on the user's authorized_groups effeciently by using a CTE
  def search_on_authorized_groups(query, use_minimum_char_limit: true)
    authorized_groups_cte = Gitlab::SQL::CTE.new(:authorized_groups, authorized_groups)
    authorized_groups_cte_alias = authorized_groups_cte.table.alias(Group.table_name)
    Group
      .with(authorized_groups_cte.to_arel)
      .from(authorized_groups_cte_alias)
      .search(query, use_minimum_char_limit: use_minimum_char_limit)
  end

  # Returns the groups a user is a member of, either directly or through a parent group
  def membership_groups
    groups.self_and_descendants
  end

  # Returns a relation of groups the user has access to, including their parent
  # and child groups (recursively).
  def all_expanded_groups
    return groups if groups.empty?

    Gitlab::ObjectHierarchy.new(groups).all_objects
  end

  def expanded_groups_requiring_two_factor_authentication
    all_expanded_groups.where(require_two_factor_authentication: true)
  end

  def source_groups_of_two_factor_authentication_requirement
    Gitlab::ObjectHierarchy.new(expanded_groups_requiring_two_factor_authentication)
      .all_objects
      .where(id: groups)
  end

  def direct_groups_with_route
    groups.with_route.order_id_asc
  end

  def first_group_paths
    first_groups = direct_groups_with_route.take(FIRST_GROUP_PATHS_LIMIT + 1)

    return if first_groups.count > FIRST_GROUP_PATHS_LIMIT

    first_groups.map(&:full_path).sort!
  end

  # rubocop: disable CodeReuse/ServiceClass
  def refresh_authorized_projects(source: nil)
    Users::RefreshAuthorizedProjectsService.new(self, source: source).execute
  end
  # rubocop: enable CodeReuse/ServiceClass

  def authorized_projects(min_access_level = nil)
    # We're overriding an association, so explicitly call super with no
    # arguments or it would be passed as `force_reload` to the association
    projects = super()

    if min_access_level
      projects = projects
        .where('project_authorizations.access_level >= ?', min_access_level)
    end

    projects
  end

  def authorized_project?(project, min_access_level = nil)
    authorized_projects(min_access_level).exists?({ id: project.id })
  end

  # Typically used in conjunction with projects table to get projects
  # a user has been given access to.
  # The param `related_project_column` is the column to compare to the
  # project_authorizations. By default is projects.id
  #
  # Example use:
  # `Project.where('EXISTS(?)', user.authorizations_for_projects)`
  def authorizations_for_projects(min_access_level: nil, related_project_column: 'projects.id')
    authorizations = project_authorizations
                      .select(1)
                      .where("project_authorizations.project_id = #{related_project_column}")

    return authorizations unless min_access_level.present?

    authorizations.where('project_authorizations.access_level >= ?', min_access_level)
  end

  # Returns the projects this user has reporter (or greater) access to, limited
  # to at most the given projects.
  #
  # This method is useful when you have a list of projects and want to
  # efficiently check to which of these projects the user has at least reporter
  # access.
  def projects_with_reporter_access_limited_to(projects)
    authorized_projects(Gitlab::Access::REPORTER).where(id: projects)
  end

  def owned_projects
    @owned_projects ||= Project.from_union(
      [
        Project.where(namespace: namespace),
        Project.joins(:project_authorizations)
          .where.not('projects.namespace_id' => namespace.id)
          .where(project_authorizations: { user_id: id, access_level: Gitlab::Access::OWNER })
      ],
      remove_duplicates: false
    )
  end

  # Returns projects which user can admin issues on (for example to move an issue to that project).
  #
  # This logic is duplicated from `Ability#project_abilities` into a SQL form.
  def projects_where_can_admin_issues
    authorized_projects(Gitlab::Access::PLANNER).non_archived.with_issues_enabled
  end

  # rubocop: disable CodeReuse/ServiceClass
  def require_ssh_key?
    count = Users::KeysCountService.new(self).count

    count == 0 && Gitlab::ProtocolAccess.allowed?('ssh')
  end
  # rubocop: enable CodeReuse/ServiceClass

  def require_password_creation_for_web?
    allow_password_authentication_for_web? && password_automatically_set?
  end

  def require_password_creation_for_git?
    allow_password_authentication_for_git? && password_automatically_set?
  end

  def require_personal_access_token_creation_for_git_auth?
    return false if allow_password_authentication_for_git? || password_based_omniauth_user?

    PersonalAccessTokensFinder.new(user: self, impersonation: false, state: 'active').execute.none?
  end

  def require_extra_setup_for_git_auth?
    require_password_creation_for_git? || require_personal_access_token_creation_for_git_auth?
  end

  def allow_password_authentication?
    allow_password_authentication_for_web? || allow_password_authentication_for_git?
  end

  def allow_password_authentication_for_web?
    return false if ldap_user?
    return false if disable_password_authentication_for_sso_users?

    Gitlab::CurrentSettings.password_authentication_enabled_for_web?
  end

  def allow_password_authentication_for_git?
    return false if password_based_omniauth_user?
    return false if disable_password_authentication_for_sso_users?

    Gitlab::CurrentSettings.password_authentication_enabled_for_git?
  end

  def can_change_username?
    gitlab_config.username_changing_enabled
  end

  def can_create_project?
    projects_limit_left > 0 && allow_user_to_create_group_and_project?
  end

  def allow_user_to_create_group_and_project?
    return true if Gitlab::CurrentSettings.allow_project_creation_for_guest_and_below
    return true if can_admin_all_resources?

    highest_role > Gitlab::Access::GUEST
  end

  def can_create_group?
    can?(:create_group)
  end

  def can_select_namespace?
    several_namespaces? || admin
  end

  def can?(action, subject = :global, **opts)
    Ability.allowed?(self, action, subject, **opts)
  end

  def confirm_deletion_with_password?
    !password_automatically_set? && allow_password_authentication?
  end

  def first_name
    read_attribute(:first_name) || begin
      name.split(' ').first unless name.blank?
    end
  end

  def last_name
    read_attribute(:last_name) || begin
      name.split(' ').drop(1).join(' ') unless name.blank?
    end
  end

  def color_mode_id
    return Gitlab::ColorModes::APPLICATION_DARK if theme_id == 11

    read_attribute(:color_mode_id)
  end

  def projects_limit_left
    projects_limit - personal_projects_count
  end

  # rubocop: disable CodeReuse/ServiceClass
  def recent_push(project = nil)
    service = Users::LastPushEventService.new(self)

    if project
      service.last_event_for_project(project)
    else
      service.last_event_for_user
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def several_namespaces?
    union_sql = ::Gitlab::SQL::Union.new(
      [owned_groups,
        maintainers_groups,
        groups_with_developer_maintainer_project_access]).to_sql

    ::Group.from("(#{union_sql}) #{::Group.table_name}").any?
  end

  def namespace_id
    namespace.try :id
  end

  def already_forked?(project)
    !!fork_of(project)
  end

  def fork_of(project)
    namespace.find_fork_of(project)
  end

  def password_based_omniauth_user?
    ldap_user? || crowd_user?
  end

  def crowd_user?
    if identities.loaded?
      identities.find { |identity| identity.provider == 'crowd' && identity.extern_uid.present? }
    else
      identities.with_any_extern_uid('crowd').exists?
    end
  end

  def ldap_user?
    if identities.loaded?
      identities.find { |identity| Gitlab::Auth::OAuth::Provider.ldap_provider?(identity.provider) && !identity.extern_uid.nil? }
    else
      identities.exists?(["provider LIKE ? AND extern_uid IS NOT NULL", "ldap%"])
    end
  end

  def ldap_identity
    @ldap_identity ||= identities.find_by(["provider LIKE ?", "ldap%"])
  end

  def matches_identity?(provider, extern_uid)
    identities.with_extern_uid(provider, extern_uid).exists?
  end

  def project_deploy_keys
    @project_deploy_keys ||= DeployKey.in_projects(authorized_projects.select(:id)).distinct(:id)
  end

  def highest_role
    user_highest_role&.highest_access_level || Gitlab::Access::NO_ACCESS
  end

  def credit_card_validated_at
    credit_card_validation&.credit_card_validated_at
  end

  def accessible_deploy_keys
    DeployKey.from_union(
      [
        DeployKey.where(id: project_deploy_keys.select(:deploy_key_id)),
        DeployKey.are_public
      ])
  end

  def sanitize_attrs
    sanitize_name
  end

  def sanitize_name
    return unless self.name

    self.name = self.name.gsub(%r{(?:</?[^>]*>|<|>)}, '-')
  end

  def unset_secondary_emails_matching_deleted_email!(deleted_email)
    secondary_email_attribute_changed = false
    SECONDARY_EMAIL_ATTRIBUTES.each do |attribute|
      if read_attribute(attribute) == deleted_email
        self.write_attribute(attribute, nil)
        secondary_email_attribute_changed = true
      end
    end
    save if secondary_email_attribute_changed
  end

  def admin_unsubscribe!
    update_column :admin_email_unsubscribed_at, Time.current
  end

  def set_projects_limit
    # `User.select(:id)` raises
    # `ActiveModel::MissingAttributeError: missing attribute: projects_limit`
    # without this safeguard!
    return unless has_attribute?(:projects_limit) && projects_limit.nil?

    self.projects_limit = Gitlab::CurrentSettings.default_projects_limit
  end

  def requires_ldap_check?
    if !Gitlab.config.ldap.enabled
      false
    elsif ldap_user?
      !last_credential_check_at || (last_credential_check_at + ldap_sync_time).past?
    else
      false
    end
  end

  def ldap_sync_time
    # This number resides in this method so it can be redefined in EE.
    1.hour
  end

  def try_obtain_ldap_lease
    # After obtaining this lease LDAP checks will be blocked for 600 seconds
    # (10 minutes) for this user.
    lease = Gitlab::ExclusiveLease.new("user_ldap_check:#{id}", timeout: 600)
    lease.try_obtain
  end

  def solo_owned_groups
    # For each owned group, count the owners found in self and ancestors.
    counts = GroupMember
      .from('unnest(namespaces.traversal_ids) AS ancestors(ancestor_id), members')
      .where('members.source_id = ancestors.ancestor_id')
      .all_by_access_level(GroupMember::OWNER)
      .having('count(members.user_id) = 1')

    Group
      .from(owned_groups, :namespaces)
      .where_exists(counts)
  end

  # All organizations that are owned by this user, and only this user.
  def solo_owned_organizations
    ownerships_cte = Gitlab::SQL::CTE.new(:ownerships, organization_users.owners, materialized: false)

    owned_orgs_from_cte = Organizations::Organization
      .joins('INNER JOIN ownerships ON ownerships.organization_id = organizations.id')

    counts = Organizations::OrganizationUser
      .owners
      .where('organization_users.organization_id = organizations.id')
      .group(:organization_id)
      .having('count(organization_users.user_id) = 1')

    Organizations::Organization
      .with(ownerships_cte.to_arel)
      .from(owned_orgs_from_cte, :organizations)
      .where_exists(counts)
  end

  def can_leave_project?(project)
    project.namespace != namespace &&
      project.member(self)
  end

  def full_website_url
    return "http://#{website_url}" unless %r{\Ahttps?://}.match?(website_url)

    website_url
  end

  def short_website_url
    website_url.sub(%r{\Ahttps?://}, '')
  end

  def all_ssh_keys
    keys.map(&:publishable_key)
  end

  def temp_oauth_email?
    email.start_with?('temp-email-for-oauth')
  end

  # rubocop: disable CodeReuse/ServiceClass
  def avatar_url(size: nil, scale: 2, **args)
    GravatarService.new.execute(email, size, scale, username: username)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def primary_email_verified?
    return false unless confirmed? && !temp_oauth_email?

    !email_changed? || new_record?
  end

  def accept_pending_invitations!
    pending_invitations.select do |member|
      member.accept_invite!(self)
    end
  end

  def pending_invitations
    Members::PendingInvitationsFinder.new(verified_emails).execute
  end

  def all_emails(include_private_email: true)
    all_emails = []
    all_emails << email unless temp_oauth_email?
    all_emails << private_commit_email if include_private_email
    all_emails.concat(emails.filter_map { |email| email.email if email.confirmed? })
    all_emails.uniq
  end

  def verified_emails(include_private_email: true)
    verified_emails = []
    verified_emails << email if primary_email_verified?
    verified_emails << private_commit_email if include_private_email
    verified_emails.concat(emails.confirmed.pluck(:email))
    verified_emails.uniq
  end

  def verified_detumbled_emails
    emails.distinct.confirmed.pluck(:detumbled_email).compact
  end

  def public_verified_emails
    strong_memoize(:public_verified_emails) do
      emails = verified_emails(include_private_email: false)
      emails << email unless temp_oauth_email?
      emails.uniq
    end
  end

  def any_email?(check_email)
    downcased = check_email.downcase

    # handle the outdated private commit email case
    return true if persisted? &&
      id == Gitlab::PrivateCommitEmail.user_id_for_email(downcased)

    all_emails.include?(check_email.downcase)
  end

  def verified_email?(check_email)
    downcased = check_email.downcase

    # handle the outdated private commit email case
    return true if persisted? &&
      id == Gitlab::PrivateCommitEmail.user_id_for_email(downcased)

    verified_emails.include?(check_email.downcase)
  end

  def hook_attrs
    {
      id: id,
      name: name,
      username: username,
      avatar_url: avatar_url(only_path: false),
      email: webhook_email
    }
  end

  def ensure_namespace_correct
    if namespace
      namespace.path = username if username_changed?
      namespace.name = name if name_changed?
    end
  end

  def assign_personal_namespace(organization)
    return namespace if namespace

    namespace_attributes = { path: username, name: name }

    # Do not explicitly assign if organization is `nil`
    namespace_attributes[:organization] = organization if organization

    build_namespace(namespace_attributes)
    namespace.build_namespace_settings

    namespace
  end

  def set_username_errors
    namespace_path_errors = self.errors.delete(:"namespace.path")

    return unless namespace_path_errors&.any?

    if namespace_path_errors.include?('has already been taken') && !User.exists?(username: username)
      self.errors.add(:base, :username_exists_as_a_different_namespace)
    else
      namespace_path_errors.each do |msg|
        # Already handled by username validation.
        next if msg.ends_with?('is a reserved name')

        self.errors.add(:username, msg)
      end
    end
  end

  def username_changed_hook
    system_hook_service.execute_hooks_for(self, :rename)
  end

  def post_destroy_hook
    log_info("User \"#{name}\" (#{email})  was removed")

    system_hook_service.execute_hooks_for(self, :destroy)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def remove_key_cache
    Users::KeysCountService.new(self).delete_cache
  end
  # rubocop: enable CodeReuse/ServiceClass

  DELETION_DELAY_IN_DAYS = 7.days

  def delete_async(deleted_by:, params: {})
    if should_delay_delete?(deleted_by)
      new_note = format(_("User deleted own account on %{timestamp}"), timestamp: Time.zone.now)
      self.note = "#{new_note}\n#{note}".strip
      UserCustomAttribute.set_deleted_own_account_at(self)

      block_or_ban
      DeleteUserWorker.perform_in(DELETION_DELAY_IN_DAYS, deleted_by.id, id, params.to_h)

      return
    end

    block if params[:hard_delete]

    DeleteUserWorker.perform_async(deleted_by.id, id, params.to_h)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def notification_service
    NotificationService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

  def log_info(message)
    Gitlab::AppLogger.info message
  end

  # rubocop: disable CodeReuse/ServiceClass
  def system_hook_service
    SystemHooksService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

  def starred?(project)
    starred_projects.exists?(project.id)
  end

  def toggle_star(project)
    UsersStarProject.transaction do
      user_star_project = users_star_projects
          .where(project: project, user: self).lock(true).first

      if user_star_project
        user_star_project.destroy
      else
        UsersStarProject.create!(project: project, user: self)
      end
    end
  end

  def following?(user)
    self.followees.exists?(user.id)
  end

  def followed_by?(user)
    self.followers.include?(user)
  end

  def follow(user)
    return false unless following_users_allowed?(user)

    begin
      followee = Users::UserFollowUser.create(follower_id: self.id, followee_id: user.id)
      self.followees.reset if followee.persisted?
      followee
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end

  def following_users_allowed?(user)
    return false if self.id == user.id

    enabled_following && user.enabled_following
  end

  def has_forkable_groups?
    Groups::AcceptingProjectCreationsFinder.new(self).execute.exists?
  end

  def forkable_namespaces
    strong_memoize(:forkable_namespaces) do
      personal_namespace = Namespace.where(id: namespace_id)
      groups_allowing_project_creation = Groups::AcceptingProjectCreationsFinder.new(self).execute

      Namespace.from_union(
        [
          groups_allowing_project_creation,
          personal_namespace
        ])
    end
  end

  def manageable_groups(include_groups_with_developer_maintainer_access: false)
    owned_and_maintainer_group_hierarchy = owned_or_maintainers_groups.self_and_descendants

    if include_groups_with_developer_maintainer_access
      union_sql = ::Gitlab::SQL::Union.new(
        [owned_and_maintainer_group_hierarchy,
          groups_with_developer_maintainer_project_access]).to_sql

      ::Group.from("(#{union_sql}) #{::Group.table_name}")
    else
      owned_and_maintainer_group_hierarchy
    end
  end

  def namespaces(owned_only: false)
    user_groups = owned_only ? owned_groups : groups
    personal_namespace = Namespace.where(id: namespace.id)

    Namespace.from_union([user_groups, personal_namespace])
  end

  def oauth_authorized_tokens
    OauthAccessToken.where(resource_owner_id: id, revoked_at: nil)
  end

  # Returns the projects a user contributed to in the last year.
  #
  # This method relies on a subquery as this performs significantly better
  # compared to a JOIN when coupled with, for example,
  # `Project.visible_to_user`. That is, consider the following code:
  #
  #     some_user.contributed_projects.visible_to_user(other_user)
  #
  # If this method were to use a JOIN the resulting query would take roughly 200
  # ms on a database with a similar size to GitLab.com's database. On the other
  # hand, using a subquery means we can get the exact same data in about 40 ms.
  def contributed_projects
    events = Event.select(:project_id)
      .contributions.where(author_id: self)
      .created_after(Time.current - 1.year)
      .distinct
      .reorder(nil)

    Project.where(id: events).not_aimed_for_deletion
  end

  # Returns true if the user can be removed, false otherwise.
  # A user can be removed if they do not own any groups or organizations where they are the sole owner
  # Method `none?` is used to ensure faster retrieval, See https://gitlab.com/gitlab-org/gitlab/-/issues/417105

  def can_be_removed?
    return solo_owned_groups.none? && solo_owned_organizations.none? if Feature.enabled?(:ui_for_organizations)

    solo_owned_groups.none?
  end

  def can_remove_self?
    true
  end

  def authorized_project_mirrors(level)
    projects = Ci::ProjectMirror.by_project_id(ci_project_ids_for_project_members(level))

    namespace_projects = Ci::ProjectMirror.by_namespace_id(ci_namespace_mirrors_for_group_members(level).select(:namespace_id))

    Ci::ProjectMirror.from_union([projects, namespace_projects])
  end

  def ci_owned_runners
    @ci_owned_runners ||= Ci::Runner
        .from_union([ci_owned_project_runners_from_project_members,
          ci_owned_project_runners_from_group_members,
          ci_owned_group_runners])
  end

  def owns_runner?(runner)
    runner = runner.__getobj__ if runner.is_a?(Ci::RunnerPresenter)

    ci_owned_runners.include?(runner)
  end

  def notification_email_for(notification_group)
    # Return group-specific email address if present, otherwise return global notification email address
    group_email = if notification_settings.loaded?
                    closest_notification_email_in_group_hierarchy(notification_group)
                  elsif notification_group && notification_group.respond_to?(:notification_email_for)
                    notification_group.notification_email_for(self)
                  end

    group_email || notification_email_or_default
  end

  def notification_settings_for(source, inherit: false)
    if notification_settings.loaded?
      notification_setting_find_by_source(source)
    else
      notification_setting_find_or_initialize_by_source(source, inherit)
    end
  end

  def notification_settings_for_groups(groups)
    ids = groups.is_a?(ActiveRecord::Relation) ? groups.select(:id) : groups.map(&:id)
    notification_settings.for_groups.where(source_id: ids)
  end

  # Lazy load global notification setting
  # Initializes User setting with Participating level if setting not persisted
  def global_notification_setting
    return @global_notification_setting if defined?(@global_notification_setting)

    # lookup in preloaded notification settings first, before making another query
    if notification_settings.loaded?
      @global_notification_setting = notification_settings.find do |notification|
        notification.source_id.nil? && notification.source_type.nil?
      end

      return @global_notification_setting if @global_notification_setting.present?
    end

    @global_notification_setting = notification_settings.find_or_initialize_by(source: nil)
    @global_notification_setting.update(level: NotificationSetting.levels[DEFAULT_NOTIFICATION_LEVEL]) unless @global_notification_setting.persisted?

    @global_notification_setting
  end

  # Returns the notification_setting of the lowest group in hierarchy with non global level
  def closest_non_global_group_notification_setting(group)
    return unless group

    notification_level = NotificationSetting.levels[:global]

    if notification_settings.loaded?
      group.self_and_ancestors_asc.find do |group|
        notification_setting = notification_setting_find_by_source(group)

        next unless notification_setting
        next if NotificationSetting.levels[notification_setting&.level] == notification_level
        break notification_setting if notification_setting.present?
      end
    else
      group.notification_settings(hierarchy_order: :asc).where(user: self).where.not(level: notification_level).first
    end
  end

  def merge_request_dashboard_enabled?
    Feature.enabled?(:merge_request_dashboard, self, type: :wip)
  end

  def assigned_open_merge_requests_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_merge_requests_count', merge_request_dashboard_enabled?], force: force, expires_in: COUNT_CACHE_VALIDITY_PERIOD) do
      params = { assignee_id: id, state: 'opened', non_archived: true }
      params[:reviewer_id] = 'none' if merge_request_dashboard_enabled?

      MergeRequestsFinder.new(self, params).execute.count
    end
  end

  def review_requested_open_merge_requests_count(force: false)
    Rails.cache.fetch(['users', id, 'review_requested_open_merge_requests_count', merge_request_dashboard_enabled?], force: force, expires_in: COUNT_CACHE_VALIDITY_PERIOD) do
      if merge_request_dashboard_enabled?
        MergeRequestsFinder.new(self, assigned_user_id: id, reviewer_review_states: %w[unreviewed unapproved review_started], assigned_review_states: %w[requested_changes reviewed], state: 'opened', non_archived: true).execute.count
      else
        MergeRequestsFinder.new(self, reviewer_id: id, state: 'opened', non_archived: true).execute.count
      end
    end
  end

  def assigned_open_issues_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_issues_count'], force: force, expires_in: COUNT_CACHE_VALIDITY_PERIOD) do
      IssuesFinder.new(self, assignee_id: self.id, state: 'opened', non_archived: true).execute.count
    end
  end

  def todos_done_count(force: false)
    Rails.cache.fetch(['users', id, 'todos_done_count'], force: force, expires_in: COUNT_CACHE_VALIDITY_PERIOD) do
      TodosFinder.new(self, state: :done).execute.count
    end
  end

  def todos_pending_count(force: false)
    Rails.cache.fetch(['users', id, 'todos_pending_count'], force: force, expires_in: COUNT_CACHE_VALIDITY_PERIOD) do
      TodosFinder.new(self, state: :pending).execute.count
    end
  end

  def personal_projects_count(force: false)
    Rails.cache.fetch(['users', id, 'personal_projects_count'], force: force, expires_in: 24.hours, raw: true) do
      personal_projects.count
    end.to_i
  end

  def update_todos_count_cache
    todos_done_count(force: true)
    todos_pending_count(force: true)
  end

  def invalidate_cache_counts
    invalidate_issue_cache_counts
    invalidate_merge_request_cache_counts
    invalidate_todos_cache_counts
    invalidate_personal_projects_count
  end

  def invalidate_issue_cache_counts
    Rails.cache.delete(['users', id, 'assigned_open_issues_count'])
    Rails.cache.delete(['users', id, 'max_assigned_open_issues_count'])
  end

  def invalidate_merge_request_cache_counts
    Rails.cache.delete(['users', id, 'assigned_open_merge_requests_count', merge_request_dashboard_enabled?])
    Rails.cache.delete(['users', id, 'review_requested_open_merge_requests_count', merge_request_dashboard_enabled?])
  end

  def invalidate_todos_cache_counts
    Rails.cache.delete(['users', id, 'todos_done_count'])
    Rails.cache.delete(['users', id, 'todos_pending_count'])
  end

  def invalidate_personal_projects_count
    Rails.cache.delete(['users', id, 'personal_projects_count'])
  end

  def invalidate_authored_todo_user_pending_todo_cache_counts
    # Invalidate the todo cache counts for other users with pending todos authored by the user
    cache_keys = authored_todos.pending.distinct.pluck(:user_id).map { |id| ['users', id, 'todos_pending_count'] }
    Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
      Rails.cache.delete_multi(cache_keys)
    end
  end

  # This is copied from Devise::Models::Lockable#valid_for_authentication?, as our auth
  # flow means we don't call that automatically (and can't conveniently do so).
  #
  # See:
  #   <https://github.com/plataformatec/devise/blob/v4.7.1/lib/devise/models/lockable.rb#L104>
  #
  # rubocop: disable CodeReuse/ServiceClass
  def increment_failed_attempts!
    return if ::Gitlab::Database.read_only?

    increment_failed_attempts

    if attempts_exceeded?
      lock_access! unless access_locked?
    else
      Users::UpdateService.new(self, user: self).execute(validate: false)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def access_level
    if admin?
      :admin
    else
      :regular
    end
  end

  def access_level=(new_level)
    new_level = new_level.to_s
    return unless %w[admin regular].include?(new_level)

    self.admin = (new_level == 'admin')
  end

  def can_read_all_resources?
    can?(:read_all_resources)
  end

  def can_admin_all_resources?
    can?(:admin_all_resources)
  end

  def owns_organization?(organization)
    strong_memoize_with(:owns_organization, organization) do
      break false unless organization

      organization_id = organization.is_a?(Integer) ? organization : organization.id

      organization_users.where(organization_id: organization_id).owner.exists?
    end
  end

  def can_admin_organization?(organization)
    can?(:admin_organization, organization)
  end

  def update_two_factor_requirement
    periods = expanded_groups_requiring_two_factor_authentication.pluck(:two_factor_grace_period)

    self.require_two_factor_authentication_from_group = periods.any?
    self.two_factor_grace_period = periods.min || User.column_defaults['two_factor_grace_period']

    save
  end

  # each existing user needs to have a `feed_token`.
  # we do this on read since migrating all existing users is not a feasible
  # solution.
  def feed_token
    ensure_feed_token! unless Gitlab::CurrentSettings.disable_feed_token
  end

  # Each existing user needs to have a `static_object_token`.
  # We do this on read since migrating all existing users is not a feasible
  # solution.
  def static_object_token
    ensure_static_object_token!
  end

  def enabled_static_object_token
    static_object_token if Gitlab::CurrentSettings.static_objects_external_storage_enabled?
  end

  def enabled_incoming_email_token
    incoming_email_token if Gitlab::Email::IncomingEmail.supports_issue_creation?
  end

  def sync_attribute?(attribute)
    return true if ldap_user? && attribute == :email

    attributes = Gitlab.config.omniauth.sync_profile_attributes

    if attributes.is_a?(Array)
      attributes.include?(attribute.to_s)
    else
      attributes
    end
  end

  def read_only_attribute?(attribute)
    user_synced_attributes_metadata&.read_only?(attribute)
  end

  # override, from Devise
  def lock_access!(opts = {})
    Gitlab::AppLogger.info("Account Locked: username=#{username}")
    audit_lock_access(reason: opts.delete(:reason))
    super
  end

  # override, from Devise
  def unlock_access!(unlocked_by: self)
    audit_unlock_access(author: unlocked_by)

    super()
  end

  # Determine the maximum access level for a group of projects in bulk.
  #
  # Returns a Hash mapping project ID -> maximum access level.
  def max_member_access_for_project_ids(project_ids)
    Gitlab::SafeRequestLoader.execute(
      resource_key: max_member_access_for_resource_key(Project),
      resource_ids: project_ids,
      default_value: Gitlab::Access::NO_ACCESS
    ) do |project_ids|
      project_authorizations.where(project: project_ids)
                            .group(:project_id)
                            .maximum(:access_level)
    end
  end

  def max_member_access_for_project(project_id)
    max_member_access_for_project_ids([project_id])[project_id]
  end

  # Determine the maximum access level for a group of groups in bulk.
  #
  # Returns a Hash mapping project ID -> maximum access level.
  def max_member_access_for_group_ids(group_ids)
    Gitlab::SafeRequestLoader.execute(
      resource_key: max_member_access_for_resource_key(Group),
      resource_ids: group_ids,
      default_value: Gitlab::Access::NO_ACCESS
    ) do |group_ids|
      group_members.where(source: group_ids).group(:source_id).maximum(:access_level)
    end
  end

  def max_member_access_for_group(group_id)
    max_member_access_for_group_ids([group_id])[group_id]
  end

  def terms_accepted?
    return true if project_bot? || service_account? || security_policy_bot? || import_user?

    if Feature.enabled?(:enforce_acceptance_of_changed_terms)
      !!ApplicationSetting::Term.latest&.accepted_by_user?(self)
    else
      accepted_term_id.present?
    end
  end

  def required_terms_not_accepted?
    Gitlab::CurrentSettings.current_application_settings.enforce_terms? &&
      !terms_accepted?
  end

  def requires_usage_stats_consent?
    self.admin? && 7.days.ago > self.created_at && !has_current_license? && User.single_user? && !consented_usage_stats?
  end

  # Avoid migrations only building user preference object when needed.
  def user_preference
    super.presence || build_user_preference
  end

  def pending_todo_for(target)
    todos.find_by(target: target, state: :pending)
  end

  def password_expired?
    !!(password_expires_at && password_expires_at.past?)
  end

  def password_expired_if_applicable?
    return false if bot?
    return false unless password_expired?
    return false if password_automatically_set?
    return false unless allow_password_authentication?

    true
  end

  def can_log_in_with_non_expired_password?
    can?(:log_in) && !password_expired_if_applicable?
  end

  def can_be_deactivated?
    active? && no_recent_activity? && !internal?
  end

  def last_active_at
    last_activity = last_activity_on&.to_time&.in_time_zone
    last_sign_in = current_sign_in_at

    [last_activity, last_sign_in].compact.max
  end

  def dismissed_callout?(feature_name:, ignore_dismissal_earlier_than: nil)
    callout = callouts_by_feature_name[feature_name]

    callout_dismissed?(callout, ignore_dismissal_earlier_than)
  end

  def dismissed_callout_for_group?(feature_name:, group:, ignore_dismissal_earlier_than: nil)
    source_feature_name = "#{feature_name}_#{group.id}"
    callout = group_callouts_by_feature_name[source_feature_name]

    callout_dismissed?(callout, ignore_dismissal_earlier_than)
  end

  def dismissed_callout_for_project?(feature_name:, project:, ignore_dismissal_earlier_than: nil)
    callout = project_callouts.find_by(feature_name: feature_name, project: project)

    callout_dismissed?(callout, ignore_dismissal_earlier_than)
  end

  # Load the current highest access by looking directly at the user's memberships
  def current_highest_access_level
    members.non_request.maximum(:access_level)
  end

  def confirmation_required_on_sign_in?
    return false if confirmed?

    if ::Gitlab::CurrentSettings.email_confirmation_setting_off?
      false
    elsif ::Gitlab::CurrentSettings.email_confirmation_setting_soft?
      !in_confirmation_period?
    elsif ::Gitlab::CurrentSettings.email_confirmation_setting_hard?
      true
    end
  end

  def impersonated?
    impersonator.present?
  end

  def created_recently?
    created_at > Devise.confirm_within.ago
  end

  def find_or_initialize_callout(feature_name)
    callouts.find_or_initialize_by(feature_name: ::Users::Callout.feature_names[feature_name])
  end

  def find_or_initialize_group_callout(feature_name, group_id)
    group_callouts
      .find_or_initialize_by(feature_name: ::Users::GroupCallout.feature_names[feature_name], group_id: group_id)
  end

  def find_or_initialize_project_callout(feature_name, project_id)
    project_callouts
      .find_or_initialize_by(feature_name: ::Users::ProjectCallout.feature_names[feature_name], project_id: project_id)
  end

  def can_trigger_notifications?
    confirmed? && !blocked? && !ghost?
  end

  # This attribute hosts a Ci::JobToken::Scope object which is set when
  # the user is authenticated successfully via CI_JOB_TOKEN.
  def ci_job_token_scope
    Gitlab::SafeRequestStore[ci_job_token_scope_cache_key]
  end

  def set_ci_job_token_scope!(job)
    Gitlab::SafeRequestStore[ci_job_token_scope_cache_key] = Ci::JobToken::Scope.new(job.project)
  end

  def from_ci_job_token?
    ci_job_token_scope.present?
  end

  def user_project
    strong_memoize(:user_project) do
      personal_projects.find_by(path: username, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end
  end

  def user_readme
    strong_memoize(:user_readme) do
      user_project&.repository&.readme
    end
  end

  def account_age_in_days
    (Date.current - created_at.to_date).to_i
  end

  def webhook_email
    public_email.presence || _('[REDACTED]')
  end

  def namespace_commit_email_for_project(project)
    return if project.nil?

    namespace_commit_emails.find_by(namespace: project.project_namespace) ||
      namespace_commit_emails.find_by(namespace: project.root_namespace)
  end

  def abuse_metadata
    {
      account_age: account_age_in_days,
      two_factor_enabled: two_factor_enabled? ? 1 : 0
    }
  end

  def trusted?
    trusted_with_spam_attribute.present?
  end

  def namespace_commit_email_for_namespace(namespace)
    return if namespace.nil?

    namespace_commit_emails.find_by(namespace: namespace)
  end

  def deleted_own_account?
    custom_attributes.by_key(UserCustomAttribute::DELETED_OWN_ACCOUNT_AT).exists?
  end

  def supports_saved_replies?
    true
  end

  def has_composite_identity?
    # Since this is called in a number of places in both Sidekiq and Web,
    # be extra paranoid that this column exists before reading it. This check
    # can be removed in GitLab 17.8 or later.
    return false unless has_attribute?(:composite_identity_enforced)

    composite_identity_enforced
  end

  def uploads_sharding_key
    {}
  end

  def add_admin_note(new_note)
    self.note = "#{new_note}\n#{self.note}"
  end

  # rubocop: disable CodeReuse/ServiceClass
  def support_pin_data
    strong_memoize(:support_pin_data) do
      Users::SupportPin::RetrieveService.new(self).execute
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def support_pin
    support_pin_data&.fetch(:pin, nil)
  end

  def support_pin_expires_at
    support_pin_data&.fetch(:expires_at, nil)
  end

  protected

  # override, from Devise::Validatable
  def password_required?
    return false if internal? || project_bot? || security_policy_bot?

    super
  end

  # override from Devise::Confirmable
  def confirmation_period_valid?
    return super if ::Gitlab::CurrentSettings.email_confirmation_setting_soft?

    # Following devise logic for method, we want to return `true`
    # See: https://github.com/heartcombo/devise/blob/ec0674523e7909579a5a008f16fb9fe0c3a71712/lib/devise/models/confirmable.rb#L191-L218
    true
  end
  alias_method :in_confirmation_period?, :confirmation_period_valid?

  # This is copied from Devise::Models::TwoFactorAuthenticatable#consume_otp!
  #
  # An OTP cannot be used more than once in a given timestep
  # Storing timestep of last valid OTP is sufficient to satisfy this requirement
  #
  # See:
  #   <https://github.com/tinfoil/devise-two-factor/blob/master/lib/devise_two_factor/models/two_factor_authenticatable.rb#L66>
  #
  def consume_otp!
    if self.consumed_timestep != current_otp_timestep
      self.consumed_timestep = current_otp_timestep
      return Gitlab::Database.read_only? ? true : save(validate: false)
    end

    false
  end

  private

  def notification_setting_find_by_source(source)
    notification_settings.find do |notification|
      notification.source_type == source.class.base_class.name && notification.source_id == source.id
    end
  end

  def closest_notification_email_in_group_hierarchy(source_group)
    return unless source_group

    source_group.self_and_ancestors_asc.find do |group|
      notification_setting = notification_setting_find_by_source(group)

      next unless notification_setting
      break notification_setting.notification_email if notification_setting.notification_email.present?
    end
  end

  def notification_setting_find_or_initialize_by_source(source, inherit)
    notification_settings.find_or_initialize_by(source: source) do |ns|
      next unless source.is_a?(Group) && inherit

      # If we're here it means we're trying to create a NotificationSetting for a group that doesn't have one.
      # Find the closest parent with a notification_setting that's not Global level, or that has an email set.
      ancestor_ns = source.notification_settings(hierarchy_order: :asc).where(user: self)
                      .find_by('level != ? OR notification_email IS NOT NULL', NotificationSetting.levels[:global])
      # Use it to seed the settings
      ns.assign_attributes(ancestor_ns&.slice(*NotificationSetting.allowed_fields))
      ns.source = source
      ns.user = self
    end
  end

  def disable_password_authentication_for_sso_users?
    ::Gitlab::CurrentSettings.disable_password_authentication_for_users_with_sso_identities? && omniauth_user?
  end

  def omniauth_user?
    identities.any?
  end

  def optional_namespace?
    Feature.enabled?(:optional_personal_namespace, self)
  end

  def block_or_ban
    user_scores = AntiAbuse::UserTrustScore.new(self)
    if user_scores.spammer? && account_age_in_days < 7
      ban_and_report
    else
      block
    end
  end

  def ban_and_report
    msg = 'Potential spammer account deletion'
    attrs = { user_id: id, reporter: Users::Internal.security_bot, category: 'spam' }
    abuse_report = AbuseReport.find_by(attrs)

    if abuse_report.nil?
      abuse_report = AbuseReport.create!(attrs.merge(message: msg))
    else
      abuse_report.update(message: "#{abuse_report.message}\n\n#{msg}")
    end

    UserCustomAttribute.set_banned_by_abuse_report(abuse_report)

    ban
  end

  def has_possible_spam_contributions?
    events
      .for_action('commented')
      .or(events.for_action('created').where(target_type: %w[Issue MergeRequest]))
      .any?
  end

  def should_delay_delete?(deleted_by)
    return false if placeholder?

    is_deleting_own_record = deleted_by.id == id

    is_deleting_own_record &&
      ::Feature.enabled?(:delay_delete_own_user) &&
      has_possible_spam_contributions?
  end

  def pbkdf2?
    return false unless otp_backup_codes&.any?

    otp_backup_codes.first.start_with?("$pbkdf2-sha512$")
  end

  # rubocop: disable CodeReuse/ServiceClass
  def add_primary_email_to_emails!
    Emails::CreateService.new(self, user: self, email: self.email).execute(confirmed_at: self.confirmed_at)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def ci_project_ids_for_project_members(level)
    project_members.where('access_level >= ?', level).pluck(:source_id)
  end

  def notification_email_verified
    return if notification_email.blank? || temp_oauth_email?

    errors.add(:notification_email, _("must be an email you have verified")) unless verified_emails.include?(notification_email_or_default)
  end

  def public_email_verified
    return if public_email.blank?

    errors.add(:public_email, _("must be an email you have verified")) unless verified_emails.include?(public_email)
  end

  def commit_email_verified
    return if commit_email.blank?

    errors.add(:commit_email, _("must be an email you have verified")) unless verified_emails.include?(commit_email_or_default)
  end

  def callout_dismissed?(callout, ignore_dismissal_earlier_than)
    return false unless callout
    return callout.dismissed_after?(ignore_dismissal_earlier_than) if ignore_dismissal_earlier_than

    true
  end

  def callouts_by_feature_name
    @callouts_by_feature_name ||= callouts.index_by(&:feature_name)
  end

  def group_callouts_by_feature_name
    @group_callouts_by_feature_name ||= group_callouts.index_by(&:source_feature_name)
  end

  def has_current_license?
    false
  end

  def consented_usage_stats?
    # Bypass the cache here because it's possible the admin enabled the
    # usage ping, and we don't want to annoy the user again if they
    # already set the value. This is a bit of hack, but the alternative
    # would be to put in a more complex cache invalidation step. Since
    # this call only gets called in the uncommon situation where the
    # user is an admin and the only user in the instance, this shouldn't
    # cause too much load on the system.
    ApplicationSetting.current_without_cache&.usage_stats_set_by_user_id == self.id
  end

  def ensure_user_rights_and_limits
    if external?
      self.can_create_group = false
      self.projects_limit   = 0
    else
      # Only revert these back to the default if they weren't specifically changed in this update.
      self.can_create_group = Gitlab::CurrentSettings.can_create_group unless can_create_group_changed?
      self.projects_limit = Gitlab::CurrentSettings.default_projects_limit unless projects_limit_changed?
    end
  end

  def email_allowed_by_restrictions
    return if placeholder? || import_user?

    error = validate_admin_signup_restrictions(email)

    errors.add(:email, error) if error
  end

  def signup_email_invalid_message
    self.new_record? ? _('is not allowed for sign-up. Please use your regular email address.') : _('is not allowed. Please use your regular email address.')
  end

  def check_username_format
    return if username.blank? || !self.class.ends_with_reserved_file_extension?(username)

    errors.add(:username, _('ending with a reserved file extension is not allowed.'))
  end

  def check_password_weakness
    if password.present? && Security::WeakPasswords.weak_for_user?(password, self)
      errors.add(:password, _('must not contain commonly used combinations of words and letters'))
    end
  end

  def groups_with_developer_maintainer_project_access
    project_creation_levels = [::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS]

    if ::Gitlab::CurrentSettings.default_project_creation == ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
      project_creation_levels << nil
    end

    developer_groups.self_and_descendants.where(project_creation_level: project_creation_levels)
  end

  def no_recent_activity?
    last_active_at.to_i <= Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_i
  end

  def update_highest_role?
    return false unless persisted?

    (previous_changes.keys & %w[state user_type]).any?
  end

  def update_highest_role_attribute
    id
  end

  def ci_job_token_scope_cache_key
    "users:#{id}:ci:job_token_scope"
  end

  # An `ldap_blocked` user will be unblocked if LDAP indicates they are allowed.
  def check_ldap_if_ldap_blocked!
    return unless ::Gitlab::Auth::Ldap::Config.enabled? && ldap_blocked?

    ::Gitlab::Auth::Ldap::Access.allowed?(self)
  end

  def ci_owned_project_runners_from_project_members
    project_ids = ci_project_ids_for_project_members(Gitlab::Access::MAINTAINER)

    Ci::Runner
      .joins(:runner_projects)
      .where(runner_projects: { project: project_ids })
  end

  def ci_owned_project_runners_from_group_members
    cte_namespace_ids = Gitlab::SQL::CTE.new(
      :cte_namespace_ids,
      ci_namespace_mirrors_for_group_members(Gitlab::Access::MAINTAINER).select(:namespace_id)
    )

    cte_project_ids = Gitlab::SQL::CTE.new(
      :cte_project_ids,
      Ci::ProjectMirror
        .select(:project_id)
        .where('ci_project_mirrors.namespace_id IN (SELECT namespace_id FROM cte_namespace_ids)')
    )

    Ci::Runner
      .with(cte_namespace_ids.to_arel)
      .with(cte_project_ids.to_arel)
      .joins(:runner_projects)
      .where('ci_runner_projects.project_id IN (SELECT project_id FROM cte_project_ids)')
  end

  def ci_owned_group_runners
    cte_namespace_ids = Gitlab::SQL::CTE.new(
      :cte_namespace_ids,
      ci_namespace_mirrors_for_group_members(Gitlab::Access::OWNER).select(:namespace_id)
    )

    Ci::Runner
      .with(cte_namespace_ids.to_arel)
      .joins(:runner_namespaces)
      .where('ci_runner_namespaces.namespace_id IN (SELECT namespace_id FROM cte_namespace_ids)')
  end

  def ci_namespace_mirrors_for_group_members(level)
    search_members = group_members.where('access_level >= ?', level)

    traversal_ids = Group.joins(:all_group_members)
      .merge(search_members)
      .shortest_traversal_ids_prefixes

    Ci::NamespaceMirror.contains_traversal_ids(traversal_ids)
  end

  def prefix_for_feed_token
    FEED_TOKEN_PREFIX
  end

  # method overridden in EE
  def audit_lock_access(reason: nil); end

  # method overridden in EE
  def audit_unlock_access(author: self); end

  def username_not_assigned_to_pages_unique_domain
    if ProjectSetting.unique_domain_exists?(username)
      # We cannot disclose the Pages unique domain, hence returning generic error message
      errors.add(:username, _('has already been taken'))
    end
  end
end

User.prepend_mod_with('User')
