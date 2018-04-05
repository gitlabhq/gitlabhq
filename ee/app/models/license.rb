class License < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  STARTER_PLAN = 'starter'.freeze
  PREMIUM_PLAN = 'premium'.freeze
  ULTIMATE_PLAN = 'ultimate'.freeze
  EARLY_ADOPTER_PLAN = 'early_adopter'.freeze

  EES_FEATURES = %i[
    audit_events
    burndown_charts
    contribution_analytics
    elastic_search
    export_issues
    external_files_in_gitlab_ci
    group_webhooks
    issuable_default_templates
    issue_board_focus_mode
    issue_weights
    jenkins_integration
    ldap_group_sync
    member_lock
    merge_request_approvers
    merge_request_squash
    multiple_ldap_servers
    multiple_issue_assignees
    multiple_project_issue_boards
    push_rules
    project_creation_level
    protected_refs_for_users
    related_issues
    repository_mirrors
    repository_size_limit
    scoped_issue_board
  ].freeze

  EEP_FEATURES = EES_FEATURES + %i[
    admin_audit_log
    auditor_user
    cross_project_pipelines
    email_additional_text
    db_load_balancing
    deploy_board
    extended_audit_events
    file_locks
    geo
    github_project_service_integration
    jira_dev_panel_integration
    ldap_group_sync_filter
    multiple_clusters
    multiple_group_issue_boards
    merge_request_performance_metrics
    object_storage
    group_saml
    service_desk
    variable_environment_scope
    reject_unsigned_commits
    commit_committer_check
    external_authorization_service
    ci_cd_projects
  ].freeze

  EEU_FEATURES = EEP_FEATURES + %i[
    dependency_scanning
    sast
    sast_container
    cluster_health
    dast
    epics
    ide
    chatops
  ].freeze

  # List all features available for early adopters,
  # i.e. users that started using GitLab.com before
  # the introduction of Bronze, Silver, Gold plans.
  # Obs.: Do not extend from other feature constants.
  # Early adopters should not earn new features as they're
  # introduced.
  EARLY_ADOPTER_FEATURES = %i[
    audit_events
    burndown_charts
    contribution_analytics
    cross_project_pipelines
    deploy_board
    export_issues
    file_locks
    group_webhooks
    issuable_default_templates
    issue_board_focus_mode
    issue_weights
    jenkins_integration
    merge_request_approvers
    merge_request_squash
    multiple_issue_assignees
    multiple_project_issue_boards
    multiple_group_issue_boards
    protected_refs_for_users
    push_rules
    related_issues
    repository_mirrors
    scoped_issue_board
    service_desk
    variable_environment_scope
  ].freeze

  FEATURES_BY_PLAN = {
    STARTER_PLAN       => EES_FEATURES,
    PREMIUM_PLAN       => EEP_FEATURES,
    ULTIMATE_PLAN      => EEU_FEATURES,
    EARLY_ADOPTER_PLAN => EARLY_ADOPTER_FEATURES
  }.freeze

  PLANS_BY_FEATURE = FEATURES_BY_PLAN.each_with_object({}) do |(plan, features), hash|
    features.each do |feature|
      hash[feature] ||= []
      hash[feature] << plan
    end
  end.freeze

  # Add on codes that may occur in legacy licenses that don't have a plan yet.
  FEATURES_FOR_ADD_ONS = {
    'GitLab_Auditor_User' => :auditor_user,
    'GitLab_DeployBoard' => :deploy_board,
    'GitLab_FileLocks' => :file_locks,
    'GitLab_Geo' => :geo,
    'GitLab_ServiceDesk' => :service_desk
  }.freeze

  # Features added here are available for all namespaces.
  ANY_PLAN_FEATURES = %i[
    ci_cd_projects
    repository_mirrors
    github_project_service_integration
  ].freeze

  # Global features that cannot be restricted to only a subset of projects or namespaces.
  # Use `License.feature_available?(:feature)` to check if these features are available.
  # For all other features, use `project.feature_available?` or `namespace.feature_available?` when possible.
  GLOBAL_FEATURES = %i[
    admin_audit_log
    auditor_user
    db_load_balancing
    elastic_search
    extended_audit_events
    geo
    ldap_group_sync
    ldap_group_sync_filter
    multiple_ldap_servers
    object_storage
    repository_size_limit
    external_authorization_service
  ].freeze

  validate :valid_license
  validate :check_users_limit, if: :new_record?, unless: :validate_with_trueup?
  validate :check_trueup, unless: :persisted?, if: :validate_with_trueup?
  validate :not_expired, unless: :persisted?

  before_validation :reset_license, if: :data_changed?

  after_create :reset_current
  after_destroy :reset_current

  scope :previous, -> { order(created_at: :desc).offset(1) }

  class << self
    def features_for_plan(plan)
      FEATURES_BY_PLAN.fetch(plan, [])
    end

    def plans_with_feature(feature)
      if global_feature?(feature)
        raise ArgumentError, "Use `License.feature_available?` for features that cannot be restricted to only a subset of projects or namespaces"
      end

      PLANS_BY_FEATURE.fetch(feature, [])
    end

    def plan_includes_feature?(plan, feature)
      plans_with_feature(feature).include?(plan)
    end

    def current
      if RequestStore.active?
        RequestStore.fetch(:current_license) { load_license }
      else
        load_license
      end
    end

    delegate :block_changes?, :feature_available?, to: :current, allow_nil: true

    def reset_current
      RequestStore.delete(:current_license)
    end

    def load_license
      return unless self.table_exists?

      license = self.last

      return unless license && license.valid?

      license
    end

    def global_feature?(feature)
      GLOBAL_FEATURES.include?(feature)
    end
  end

  def data_filename
    company_name = self.licensee["Company"] || self.licensee.values.first
    clean_company_name = company_name.gsub(/[^A-Za-z0-9]/, "")
    "#{clean_company_name}.gitlab-license"
  end

  def data_file=(file)
    self.data = file.read
  end

  def md5
    normalized_data = self.data.gsub("\r\n", "\n").gsub(/\n+$/, '') + "\n"

    Digest::MD5.hexdigest(normalized_data)
  end

  def license
    return nil unless self.data

    @license ||=
      begin
        Gitlab::License.import(self.data)
      rescue Gitlab::License::ImportError
        nil
      end
  end

  def license?
    self.license && self.license.valid?
  end

  def method_missing(method_name, *arguments, &block)
    if License.column_names.include?(method_name.to_s)
      super
    elsif license && license.respond_to?(method_name)
      license.__send__(method_name, *arguments, &block) # rubocop:disable GitlabSecurity/PublicSend
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    if License.column_names.include?(method_name.to_s)
      super
    elsif license && license.respond_to?(method_name)
      true
    else
      super
    end
  end

  # New licenses persists only the `plan` (premium, starter, ..). But, old licenses
  # keep `add_ons`.
  def add_ons
    restricted_attr(:add_ons, {})
  end

  def features_from_add_ons
    add_ons.map { |name, count| FEATURES_FOR_ADD_ONS[name] if count.to_i > 0 }.compact
  end

  def features
    @features ||= (self.class.features_for_plan(plan) + features_from_add_ons).to_set
  end

  def feature_available?(feature)
    return false if trial? && expired?

    features.include?(feature)
  end

  def license_id
    restricted_attr(:id)
  end

  def restricted_user_count
    restricted_attr(:active_user_count)
  end

  def previous_user_count
    restricted_attr(:previous_user_count)
  end

  def plan
    restricted_attr(:plan).presence || STARTER_PLAN
  end

  def current_active_users_count
    @current_active_users_count ||= User.active.count
  end

  def validate_with_trueup?
    [restricted_attr(:trueup_quantity),
     restricted_attr(:trueup_from),
     restricted_attr(:trueup_to)].all?(&:present?)
  end

  def trial?
    restricted_attr(:trial)
  end

  def active?
    !expired?
  end

  def remaining_days
    return 0 if expired?

    (expires_at - Date.today).to_i
  end

  private

  def restricted_attr(name, default = nil)
    return default unless license? && restricted?(name)

    restrictions[name]
  end

  def reset_current
    self.class.reset_current
    Gitlab::Chat.flush_available_cache
  end

  def reset_license
    @license = nil
  end

  def valid_license
    return if license?

    self.errors.add(:base, "The license key is invalid. Make sure it is exactly as you received it from GitLab Inc.")
  end

  def historical_max(from = nil, to = nil)
    from ||= starts_at - 1.year
    to   ||= starts_at

    HistoricalData.during(from..to).maximum(:active_user_count) || 0
  end

  def empty_historical_max?
    historical_max == 0
  end

  def check_users_limit
    return unless restricted_user_count

    if previous_user_count && (historical_max <= previous_user_count)
      return if restricted_user_count >= current_active_users_count
    else
      return if restricted_user_count >= historical_max
    end

    user_count = empty_historical_max? ? current_active_users_count : historical_max

    add_limit_error(current_period: empty_historical_max?, user_count: user_count)
  end

  def check_trueup
    trueup_qty          = restrictions[:trueup_quantity]
    trueup_from         = Date.parse(restrictions[:trueup_from]) rescue (starts_at - 1.year)
    trueup_to           = Date.parse(restrictions[:trueup_to]) rescue starts_at
    max_historical      = historical_max(trueup_from, trueup_to)
    expected_trueup_qty = if previous_user_count
                            max_historical - previous_user_count
                          else
                            max_historical - current_active_users_count
                          end

    if trueup_qty >= expected_trueup_qty
      if restricted_user_count < current_active_users_count
        add_limit_error(user_count: current_active_users_count)
      end
    else
      message = "You have applied a True-up for #{trueup_qty} #{"user".pluralize(trueup_qty)} "
      message << "but you need one for #{expected_trueup_qty} #{"user".pluralize(expected_trueup_qty)}. "
      message << "Please contact sales at renewals@gitlab.com"

      self.errors.add(:base, message)
    end
  end

  def add_limit_error(current_period: true, user_count:)
    overage = user_count - restricted_user_count

    message =  current_period ? "This GitLab installation currently has " : "During the year before this license started, this GitLab installation had "
    message << "#{number_with_delimiter(user_count)} active #{"user".pluralize(user_count)}, "
    message << "exceeding this license's limit of #{number_with_delimiter(restricted_user_count)} by "
    message << "#{number_with_delimiter(overage)} #{"user".pluralize(overage)}. "
    message << "Please upload a license for at least "
    message << "#{number_with_delimiter(user_count)} #{"user".pluralize(user_count)} or contact sales at renewals@gitlab.com"

    self.errors.add(:base, message)
  end

  def not_expired
    return unless self.license? && self.expired?

    self.errors.add(:base, "This license has already expired.")
  end
end
