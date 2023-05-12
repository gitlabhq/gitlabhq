# frozen_string_literal: true

class PersonalAccessToken < ApplicationRecord
  include Expirable
  include TokenAuthenticatable
  include Sortable
  include EachBatch
  include CreatedAtFilterable
  include Gitlab::SQL::Pattern
  extend ::Gitlab::Utils::Override

  add_authentication_token_field :token,
    digest: true,
    format_with_prefix: :prefix_from_application_current_settings

  # PATs are 20 characters + optional configurable settings prefix (0..20)
  TOKEN_LENGTH_RANGE = (20..40).freeze
  MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS = 365

  serialize :scopes, Array # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :user

  after_initialize :set_default_scopes, if: :persisted?
  before_save :ensure_token

  # During the implementation of Admin Mode for API, tokens of
  # administrators should automatically get the `admin_mode` scope as well
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/42692
  before_create :add_admin_mode_scope, if: -> { Feature.disabled?(:admin_mode_for_api) && user_admin? }

  scope :active, -> { not_revoked.not_expired }
  scope :expiring_and_not_notified, ->(date) { where(["revoked = false AND expire_notification_delivered = false AND expires_at >= CURRENT_DATE AND expires_at <= ?", date]) }
  scope :expired_today_and_not_notified, -> { where(["revoked = false AND expires_at = CURRENT_DATE AND after_expiry_notification_delivered = false"]) }
  scope :inactive, -> { where("revoked = true OR expires_at < CURRENT_DATE") }
  scope :last_used_before_or_unused, -> (date) { where("personal_access_tokens.created_at < :date AND (last_used_at < :date OR last_used_at IS NULL)", date: date) }
  scope :with_impersonation, -> { where(impersonation: true) }
  scope :without_impersonation, -> { where(impersonation: false) }
  scope :revoked, -> { where(revoked: true) }
  scope :not_revoked, -> { where(revoked: [false, nil]) }
  scope :for_user, -> (user) { where(user: user) }
  scope :for_users, -> (users) { where(user: users) }
  scope :preload_users, -> { preload(:user) }
  scope :order_expires_at_asc_id_desc, -> { reorder(expires_at: :asc, id: :desc) }
  scope :project_access_token, -> { includes(:user).references(:user).merge(User.project_bot) }
  scope :owner_is_human, -> { includes(:user).references(:user).merge(User.human) }
  scope :last_used_before, -> (date) { where("last_used_at <= ?", date) }
  scope :last_used_after, -> (date) { where("last_used_at >= ?", date) }

  validates :scopes, presence: true
  validate :validate_scopes
  validate :expires_at_before_instance_max_expiry_date, on: :create

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked? && !expired?
  end

  # fall back to default value until background migration has updated all
  # existing PATs and we can add a validation
  # https://gitlab.com/gitlab-org/gitlab/-/issues/369123
  def expires_at=(value)
    datetime = if Feature.enabled?(:default_pat_expiration)
                 value.presence || MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now
               else
                 value
               end

    super(datetime)
  end

  override :simple_sorts
  def self.simple_sorts
    super.merge(
      {
        'expires_at_asc_id_desc' => -> { order_expires_at_asc_id_desc }
      }
    )
  end

  def self.token_prefix
    Gitlab::CurrentSettings.current_application_settings.personal_access_token_prefix
  end

  def self.search(query)
    fuzzy_search(query, [:name])
  end

  def project_access_token?
    user&.project_bot?
  end

  protected

  def validate_scopes
    valid_scopes = Gitlab::Auth.all_available_scopes
    valid_scopes += [Gitlab::Auth::ADMIN_MODE_SCOPE] if Feature.disabled?(:admin_mode_for_api)

    unless revoked || scopes.all? { |scope| valid_scopes.include?(scope.to_sym) }
      errors.add :scopes, "can only contain available scopes"
    end
  end

  def set_default_scopes
    # When only loading a select set of attributes, for example using `EachBatch`,
    # the `scopes` attribute is not present, so we can't initialize it.
    return unless has_attribute?(:scopes)

    self.scopes = Gitlab::Auth::DEFAULT_SCOPES if self.scopes.empty?
  end

  def user_admin?
    user.admin? # rubocop: disable Cop/UserAdmin
  end

  def add_admin_mode_scope
    self.scopes += [Gitlab::Auth::ADMIN_MODE_SCOPE.to_s]
  end

  def prefix_from_application_current_settings
    self.class.token_prefix
  end

  def expires_at_before_instance_max_expiry_date
    return unless Feature.enabled?(:default_pat_expiration)
    return unless expires_at

    if expires_at > MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now
      errors.add(:expires_at, _('must expire in 365 days'))
    end
  end
end

PersonalAccessToken.prepend_mod_with('PersonalAccessToken')
