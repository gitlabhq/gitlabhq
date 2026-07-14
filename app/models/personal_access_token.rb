# frozen_string_literal: true

class PersonalAccessToken < ApplicationRecord
  include AfterCommitQueue
  include Expirable
  include TokenAuthenticatable
  include Sortable
  include EachBatch
  include CreatedAtFilterable
  include Gitlab::SQL::Pattern
  include SafelyChangeColumnDefault
  include PolicyActor

  extend ::Gitlab::Utils::Override

  NOTIFICATION_INTERVALS = {
    seven_days: 0..7,
    thirty_days: 8..30,
    sixty_days: 31..60
  }.freeze

  PERSONAL_TOKEN_PREFIX = 'glpat-'

  CREATION_SOURCE_UI = 'ui'
  CREATION_SOURCE_API = 'api'
  CREATION_SOURCE_UNKNOWN = 'unknown'

  add_authentication_token_field :token,
    digest: true,
    format_with_prefix: :prefix_from_application_current_settings,
    routable_token: {
      payload: {
        o: ->(token_owner_record) { token_owner_record.organization_id },
        u: ->(token_owner_record) { token_owner_record.user_id }
      }
    }

  columns_changing_default :organization_id

  attribute :organization_id, default: -> { Organizations::Organization::DEFAULT_ORGANIZATION_ID }

  MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS_BUFFERED = 400
  MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS = 365

  MAX_DESCRIPTION_LENGTH = 255

  serialize :scopes, type: Array # rubocop:disable Cop/ActiveRecordSerialize

  enum :user_type, HasUserType::USER_TYPES

  belongs_to :user
  belongs_to :group
  belongs_to :organization, class_name: 'Organizations::Organization'
  belongs_to :previous_personal_access_token, class_name: 'PersonalAccessToken'

  has_many :last_used_ips, class_name: 'Authn::PersonalAccessTokenLastUsedIp'
  has_many :personal_access_token_granular_scopes, class_name: 'Authz::PersonalAccessTokenGranularScope', autosave: true
  has_many :granular_scopes, through: :personal_access_token_granular_scopes, class_name: 'Authz::GranularScope'

  after_initialize :set_default_scopes, if: :persisted?
  before_save :ensure_token

  before_create :set_user_type
  before_create :set_group_id

  scope :active, -> { not_revoked.not_expired }
  # this scope must use a string condition, otherwise Postgres will not use the correct indices
  scope :expiring_and_not_notified, ->(date) { where(["revoked = false AND expire_notification_delivered = false AND seven_days_notification_sent_at IS NULL AND expires_at >= CURRENT_DATE AND expires_at <= ?", date]) }
  scope :expired_today_and_not_notified, -> { where(["revoked = false AND expires_at = CURRENT_DATE AND after_expiry_notification_delivered = false"]) }
  scope :expired_after, ->(date) { expired.where(arel_table[:expires_at].gteq(date)) }
  scope :expires_before, ->(date) { where(arel_table[:expires_at].lt(date)) }
  scope :expires_after, ->(date) { where(arel_table[:expires_at].gteq(date)) }
  scope :inactive, -> { revoked.or(expired) }
  scope :last_used_before_or_unused, ->(date) { where("personal_access_tokens.created_at < :date AND (last_used_at < :date OR last_used_at IS NULL)", date: date) }
  scope :with_impersonation, -> { where(impersonation: true) }
  scope :without_impersonation, -> { where(impersonation: false) }
  scope :revoked, -> { where(revoked: true) }
  scope :revoked_after, ->(date) { revoked.where(arel_table[:updated_at].gteq(date)) }
  scope :not_revoked, -> { where(revoked: [false, nil]) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_users, ->(users) { where(user: users) }
  scope :for_user_types, ->(user_types) { where(user_type: user_types) }
  scope :in_organization, ->(organization) { where(organization_id: organization) }
  scope :for_group, ->(group) { where(group: group) }
  scope :preload_users, -> { preload(:user) }
  scope :preload_granular_scopes, -> { preload(granular_scopes: [:namespace]) }
  scope :preload_last_used_ips, -> { preload(:last_used_ips) }
  scope :preload_bot_user_associations_for_group, -> { preload(user: [:members, { user_detail: :bot_namespace }]) }
  scope :preload_bot_user_associations_for_project, -> {
    preload(user: [:members, { user_detail: { bot_namespace: :project } }])
  }
  scope :order_name_asc_id_asc, -> { reorder(name: :asc, id: :asc) }
  scope :order_name_desc_id_desc, -> { reorder(name: :desc, id: :desc) }
  scope :order_created_at_asc_id_asc, -> { reorder(created_at: :asc, id: :asc) }
  scope :order_created_at_desc_id_desc, -> { reorder(created_at: :desc, id: :desc) }
  scope :order_expires_at_asc_id_asc, -> { reorder(expires_at: :asc, id: :asc) }
  scope :order_expires_at_desc_id_desc, -> { reorder(expires_at: :desc, id: :desc) }
  scope :order_last_used_at_asc_id_asc, -> { reorder(last_used_at: :asc, id: :asc) }
  scope :order_last_used_at_desc_id_desc, -> { reorder(last_used_at: :desc, id: :desc) }
  scope :project_access_token, -> { includes(:user).references(:user).merge(User.project_bot) }
  scope :last_used_before, ->(date) { where("last_used_at <= ?", date) }
  scope :last_used_after, ->(date) { where("last_used_at >= ?", date) }
  scope :expiring_and_not_notified_without_impersonation, -> {
    expiring_and_not_notified(DAYS_TO_EXPIRE.days.from_now.to_date).without_impersonation
  }
  scope :with_token_digests, ->(digests) { where(token_digest: digests) }

  validates :name, :scopes, presence: true
  validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH }, allow_blank: true
  validates :expires_at, presence: true, on: :create, unless: :allow_expires_at_to_be_empty?

  validate :validate_scopes
  validate :expires_at_before_instance_max_expiry_date, on: :create
  validate :sudo_only_for_admins

  def permitted_for_boundary?(boundary, permissions)
    return false if legacy?

    unless granular_scopes.loaded?
      ActiveRecord::Associations::Preloader.new(
        records: [self],
        associations: :granular_scopes
      ).call
    end

    required_permissions = Array(permissions).map(&:to_sym)
    token_permissions = granular_scopes
      .select { |granular_scope| granular_scope.applicable_to_boundary?(boundary) }
      .flat_map(&:expanded_permissions)

    (required_permissions - token_permissions).empty?
  end

  def revoke!
    return true if revoked?

    if persisted?
      update_columns(revoked: true, updated_at: Time.zone.now)
    else
      self.revoked = true
    end
  end

  def active?
    return false if revoked?
    return false if expired?
    return false if granular? && ::Feature.disabled?(:granular_personal_access_tokens, user)

    true
  end

  override :simple_sorts
  def self.simple_sorts
    super.merge(
      {
        'name_asc' => -> { order_name_asc_id_asc },
        'name_desc' => -> { order_name_desc_id_desc },
        'created_asc' => -> { order_created_at_asc_id_asc },
        'created_desc' => -> { order_created_at_desc_id_desc },
        'expires_asc' => -> { order_expires_at_asc_id_asc },
        'expires_desc' => -> { order_expires_at_desc_id_desc },
        'last_used_asc' => -> { order_last_used_at_asc_id_asc },
        'last_used_desc' => -> { order_last_used_at_desc_id_desc }
      }
    )
  end

  def self.token_prefix
    # Instance wide token prefixes take precedence over the personal_access_token_prefix
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/388379#note_2477892999
    if ::Authn::TokenField::PrefixHelper.instance_prefix.blank?
      Gitlab::CurrentSettings.current_application_settings.personal_access_token_prefix
    else
      ::Authn::TokenField::PrefixHelper.prepend_instance_prefix(PERSONAL_TOKEN_PREFIX)
    end
  end

  def self.search(query)
    fuzzy_search(query, [:name])
  end

  def self.notification_interval(interval)
    NOTIFICATION_INTERVALS.fetch(interval).max
  end

  def self.scope_for_notification_interval(interval, min_expires_at: nil, max_expires_at: nil)
    interval_range = NOTIFICATION_INTERVALS.fetch(interval).minmax
    min_expiry_date, max_expiry_date = interval_range.map { |range| Date.current + range }
    min_expiry_date = min_expires_at if min_expires_at
    max_expiry_date = max_expires_at if max_expires_at
    interval_attr = "#{interval}_notification_sent_at"

    sql_string = <<~SQL
      revoked = FALSE
      AND #{interval_attr} IS NULL
      AND expire_notification_delivered = FALSE
      AND expires_at BETWEEN ? AND ?
    SQL

    # this scope must use a string condition rather than activerecord syntax,
    # otherwise Postgres will not use the correct indices
    where(sql_string, min_expiry_date, max_expiry_date).without_impersonation
  end

  def self.max_expiration_lifetime_in_days
    if ::Feature.enabled?(:buffered_token_expiration_limit) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Group setting but checked at user
      MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS_BUFFERED
    else
      MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS
    end
  end

  def hook_attrs
    Gitlab::HookData::ResourceAccessTokenBuilder.new(self).build
  end

  def legacy?
    !granular
  end

  protected

  def set_user_type
    self.user_type = user.user_type
  end

  def set_group_id
    if user.project_bot? && user.bot_namespace&.root_ancestor.is_a?(Group)
      self.group_id = user.bot_namespace.root_ancestor.id
    end
  end

  def validate_scopes
    unless revoked || scopes.all? { |scope| Gitlab::Auth.all_available_scopes.include?(scope.to_sym) }
      errors.add :scopes, "can only contain available scopes"
    end
  end

  def sudo_only_for_admins
    return unless sudo?
    return if user&.can_admin_all_resources?

    errors.add :sudo, _('can only be enabled for administrators')
  end

  def set_default_scopes
    # When only loading a select set of attributes, for example using `EachBatch`,
    # the `scopes` attribute is not present, so we can't initialize it.
    return unless has_attribute?(:scopes)

    self.scopes = Gitlab::Auth::DEFAULT_SCOPES if self.scopes.empty?
  end

  def prefix_from_application_current_settings
    self.class.token_prefix
  end

  def allow_expires_at_to_be_empty?
    !Gitlab::CurrentSettings.require_personal_access_token_expiry?
  end

  def max_expiration_lifetime_in_days
    self.class.max_expiration_lifetime_in_days
  end

  def expires_at_before_instance_max_expiry_date
    return unless expires_at

    return unless Gitlab::CurrentSettings.require_personal_access_token_expiry?

    max_expiry_date = Date.current.advance(days: max_expiration_lifetime_in_days)
    return unless expires_at > max_expiry_date

    errors.add(
      :expires_at,
      format(_("must be before %{expiry_date}"), expiry_date: max_expiry_date)
    )
  end
end

PersonalAccessToken.prepend_mod_with('PersonalAccessToken')
