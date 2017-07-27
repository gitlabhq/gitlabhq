class License < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  ADMIN_AUDIT_LOG_FEATURE = 'GitLab_AdminAuditLog'.freeze
  AUDIT_EVENTS_FEATURE = 'GitLab_AuditEvents'.freeze
  AUDITOR_USER_FEATURE = 'GitLab_Auditor_User'.freeze
  BURNDOWN_CHARTS_FEATURE = 'GitLab_BurndownCharts'.freeze
  CONTRIBUTION_ANALYTICS_FEATURE = 'GitLab_ContributionAnalytics'.freeze
  DB_LOAD_BALANCING_FEATURE = 'GitLab_DbLoadBalancing'.freeze
  DEPLOY_BOARD_FEATURE = 'GitLab_DeployBoard'.freeze
  ELASTIC_SEARCH_FEATURE = 'GitLab_ElasticSearch'.freeze
  EXPORT_ISSUES_FEATURE  = 'GitLab_ExportIssues'.freeze
  FAST_FORWARD_MERGE_FEATURE = 'GitLab_FastForwardMerge'.freeze
  FILE_LOCKS_FEATURE = 'GitLab_FileLocks'.freeze
  GEO_FEATURE = 'GitLab_Geo'.freeze
  GROUP_WEBHOOKS_FEATURE = 'GitLab_GroupWebhooks'.freeze
  ISSUABLE_DEFAULT_TEMPLATES_FEATURE = 'GitLab_IssuableDefaultTemplates'.freeze
  ISSUE_BOARD_FOCUS_MODE_FEATURE = 'GitLab_IssueBoardFocusMode'.freeze
  ISSUE_BOARD_MILESTONE_FEATURE = 'GitLab_IssueBoardMilestone'.freeze
  ISSUE_WEIGHTS_FEATURE = 'GitLab_IssueWeights'.freeze
  JENKINS_INTEGRATION_FEATURE = 'GitLab_JenkinsIntegration'.freeze
  MERGE_REQUEST_APPROVERS_FEATURE = 'GitLab_MergeRequestApprovers'.freeze
  MERGE_REQUEST_REBASE_FEATURE = 'GitLab_MergeRequestRebase'.freeze
  MERGE_REQUEST_SQUASH_FEATURE = 'GitLab_MergeRequestSquash'.freeze
  MULTIPLE_ISSUE_ASSIGNEES_FEATURE = 'GitLab_MultipleIssueAssignees'.freeze
  MULTIPLE_ISSUE_BOARDS_FEATURE = 'GitLab_MultipleIssueBoards'.freeze
  OBJECT_STORAGE_FEATURE = 'GitLab_ObjectStorage'.freeze
  PROTECTED_REFS_FOR_USERS_FEATURE = 'GitLab_RefPermissionsForUsers'.freeze
  PUSH_RULES_FEATURE = 'GitLab_PushRules'.freeze
  RELATED_ISSUES_FEATURE = 'GitLab_RelatedIssues'.freeze
  REPOSITORY_MIRRORS_FEATURE = 'GitLab_RepositoryMirrors'.freeze
  REPOSITORY_SIZE_LIMIT_FEATURE = 'GitLab_RepositorySizeLimit'.freeze
  SERVICE_DESK_FEATURE = 'GitLab_ServiceDesk'.freeze
  VARIABLE_ENVIRONMENT_SCOPE_FEATURE = 'GitLab_VariableEnvironmentScope'.freeze

  FEATURE_CODES = {
    admin_audit_log: ADMIN_AUDIT_LOG_FEATURE,
    auditor_user: AUDITOR_USER_FEATURE,
    db_load_balancing: DB_LOAD_BALANCING_FEATURE,
    elastic_search: ELASTIC_SEARCH_FEATURE,
    geo: GEO_FEATURE,
    object_storage: OBJECT_STORAGE_FEATURE,
    related_issues: RELATED_ISSUES_FEATURE,
    repository_size_limit: REPOSITORY_SIZE_LIMIT_FEATURE,
    service_desk: SERVICE_DESK_FEATURE,
    variable_environment_scope: VARIABLE_ENVIRONMENT_SCOPE_FEATURE,

    # Features that make sense to Namespace:
    audit_events: AUDIT_EVENTS_FEATURE,
    burndown_charts: BURNDOWN_CHARTS_FEATURE,
    contribution_analytics: CONTRIBUTION_ANALYTICS_FEATURE,
    deploy_board: DEPLOY_BOARD_FEATURE,
    export_issues: EXPORT_ISSUES_FEATURE,
    fast_forward_merge: FAST_FORWARD_MERGE_FEATURE,
    file_locks: FILE_LOCKS_FEATURE,
    group_webhooks: GROUP_WEBHOOKS_FEATURE,
    issuable_default_templates: ISSUABLE_DEFAULT_TEMPLATES_FEATURE,
    issue_board_focus_mode: ISSUE_BOARD_FOCUS_MODE_FEATURE,
    issue_board_milestone: ISSUE_BOARD_MILESTONE_FEATURE,
    issue_weights: ISSUE_WEIGHTS_FEATURE,
    jenkins_integration: JENKINS_INTEGRATION_FEATURE,
    merge_request_approvers: MERGE_REQUEST_APPROVERS_FEATURE,
    merge_request_rebase: MERGE_REQUEST_REBASE_FEATURE,
    merge_request_squash: MERGE_REQUEST_SQUASH_FEATURE,
    multiple_issue_assignees: MULTIPLE_ISSUE_ASSIGNEES_FEATURE,
    multiple_issue_boards: MULTIPLE_ISSUE_BOARDS_FEATURE,
    protected_refs_for_users: PROTECTED_REFS_FOR_USERS_FEATURE,
    push_rules: PUSH_RULES_FEATURE,
    repository_mirrors: REPOSITORY_MIRRORS_FEATURE
  }.freeze

  STARTER_PLAN = 'starter'.freeze
  PREMIUM_PLAN = 'premium'.freeze
  ULTIMATE_PLAN = 'ultimate'.freeze
  EARLY_ADOPTER_PLAN = 'early_adopter'.freeze

  EES_FEATURES = [
    { AUDIT_EVENTS_FEATURE => 1 },
    { BURNDOWN_CHARTS_FEATURE => 1 },
    { CONTRIBUTION_ANALYTICS_FEATURE => 1 },
    { ELASTIC_SEARCH_FEATURE => 1 },
    { EXPORT_ISSUES_FEATURE => 1 },
    { FAST_FORWARD_MERGE_FEATURE => 1 },
    { GROUP_WEBHOOKS_FEATURE => 1 },
    { ISSUABLE_DEFAULT_TEMPLATES_FEATURE => 1 },
    { ISSUE_BOARD_FOCUS_MODE_FEATURE => 1 },
    { ISSUE_BOARD_MILESTONE_FEATURE => 1 },
    { ISSUE_WEIGHTS_FEATURE => 1 },
    { JENKINS_INTEGRATION_FEATURE => 1 },
    { MERGE_REQUEST_APPROVERS_FEATURE => 1 },
    { MERGE_REQUEST_REBASE_FEATURE => 1 },
    { MERGE_REQUEST_SQUASH_FEATURE => 1 },
    { MULTIPLE_ISSUE_ASSIGNEES_FEATURE => 1 },
    { MULTIPLE_ISSUE_BOARDS_FEATURE => 1 },
    { PUSH_RULES_FEATURE => 1 },
    { PROTECTED_REFS_FOR_USERS_FEATURE => 1 },
    { RELATED_ISSUES_FEATURE => 1 },
    { REPOSITORY_MIRRORS_FEATURE => 1 },
    { REPOSITORY_SIZE_LIMIT_FEATURE => 1 }
  ].freeze

  EEP_FEATURES = [
    *EES_FEATURES,
    { ADMIN_AUDIT_LOG_FEATURE => 1 },
    { AUDITOR_USER_FEATURE => 1 },
    { DB_LOAD_BALANCING_FEATURE => 1 },
    { DEPLOY_BOARD_FEATURE => 1 },
    { FILE_LOCKS_FEATURE => 1 },
    { GEO_FEATURE => 1 },
    { OBJECT_STORAGE_FEATURE => 1 },
    { SERVICE_DESK_FEATURE => 1 },
    { VARIABLE_ENVIRONMENT_SCOPE_FEATURE => 1 }
  ].freeze

  EEU_FEATURES = [
    *EEP_FEATURES
    # ..
  ].freeze

  # List all features available for early adopters,
  # i.e. users that started using GitLab.com before
  # the introduction of Bronze, Silver, Gold plans.
  # Obs.: Do not extend from other feature constants.
  # Early adopters should not earn new features as they're
  # introduced.
  EARLY_ADOPTER_FEATURES = [
    { AUDIT_EVENTS_FEATURE => 1 },
    { AUDITOR_USER_FEATURE => 1 },
    { BURNDOWN_CHARTS_FEATURE => 1 },
    { CONTRIBUTION_ANALYTICS_FEATURE => 1 },
    { DEPLOY_BOARD_FEATURE => 1 },
    { EXPORT_ISSUES_FEATURE => 1 },
    { FAST_FORWARD_MERGE_FEATURE => 1 },
    { FILE_LOCKS_FEATURE => 1 },
    { GEO_FEATURE => 1 },
    { GROUP_WEBHOOKS_FEATURE => 1 },
    { ISSUABLE_DEFAULT_TEMPLATES_FEATURE => 1 },
    { ISSUE_BOARD_FOCUS_MODE_FEATURE => 1 },
    { ISSUE_BOARD_MILESTONE_FEATURE => 1 },
    { ISSUE_WEIGHTS_FEATURE => 1 },
    { MERGE_REQUEST_APPROVERS_FEATURE => 1 },
    { MERGE_REQUEST_REBASE_FEATURE => 1 },
    { MERGE_REQUEST_SQUASH_FEATURE => 1 },
    { MULTIPLE_ISSUE_ASSIGNEES_FEATURE => 1 },
    { MULTIPLE_ISSUE_BOARDS_FEATURE => 1 },
    { OBJECT_STORAGE_FEATURE => 1 },
    { PROTECTED_REFS_FOR_USERS_FEATURE => 1 },
    { PUSH_RULES_FEATURE => 1 },
    { REPOSITORY_MIRRORS_FEATURE => 1 },
    { SERVICE_DESK_FEATURE => 1 }
  ].freeze

  FEATURES_BY_PLAN = {
    STARTER_PLAN       => EES_FEATURES,
    PREMIUM_PLAN       => EEP_FEATURES,
    ULTIMATE_PLAN      => EEU_FEATURES,
    EARLY_ADOPTER_PLAN => EARLY_ADOPTER_FEATURES
  }.freeze

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
      FEATURES_BY_PLAN.fetch(plan, []).reduce({}, :merge)
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

    def plan_includes_feature?(plan, code)
      features = features_for_plan(plan)
      feature = FEATURE_CODES.fetch(code)

      features[feature].to_i > 0
    end

    def load_license
      license = self.last

      return unless license && license.valid?
      license
    end

    def trial
      all.detect { |license| license.trial? }
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
      license.send(method_name, *arguments, &block)
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
  # keep `add_ons`, therefore this method needs to be backward-compatible in that sense.
  # See https://gitlab.com/gitlab-org/gitlab-ee/issues/2019
  def add_ons
    explicit_add_ons = restricted_attr(:add_ons, {})
    plan_features = self.class.features_for_plan(plan)

    explicit_add_ons.merge(plan_features)
  end

  def feature_available?(code)
    return false if trial? && expired?

    feature = FEATURE_CODES.fetch(code)
    add_ons[feature].to_i > 0
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

  def check_users_limit
    return unless restricted_user_count

    if previous_user_count && (historical_max <= previous_user_count)
      return if restricted_user_count >= current_active_users_count
    else
      return if restricted_user_count >= historical_max
    end

    overage = historical_max - restricted_user_count
    add_limit_error(user_count: historical_max, restricted_user_count: restricted_user_count, overage: overage)
  end

  def check_trueup
    trueup_qty          = restrictions[:trueup_quantity]
    trueup_from         = Date.parse(restrictions[:trueup_from]) rescue (starts_at - 1.year)
    trueup_to           = Date.parse(restrictions[:trueup_to]) rescue starts_at
    max_historical      = historical_max(trueup_from, trueup_to)
    overage             = current_active_users_count - restricted_user_count
    expected_trueup_qty = if previous_user_count
                            max_historical - previous_user_count
                          else
                            max_historical - current_active_users_count
                          end

    if trueup_qty >= expected_trueup_qty
      if restricted_user_count < current_active_users_count
        add_limit_error(trueup: true, user_count: current_active_users_count, restricted_user_count: restricted_user_count, overage: overage)
      end
    else
      message = "You have applied a True-up for #{trueup_qty} #{"user".pluralize(trueup_qty)} "
      message << "but you need one for #{expected_trueup_qty} #{"user".pluralize(expected_trueup_qty)}. "
      message << "Please contact sales at renewals@gitlab.com"

      self.errors.add(:base, message)
    end
  end

  def add_limit_error(trueup: false, user_count:, restricted_user_count:, overage:)
    message =  trueup ? "This GitLab installation currently has " : "During the year before this license started, this GitLab installation had "
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
