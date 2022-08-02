# frozen_string_literal: true

class ProjectFeature < ApplicationRecord
  include Featurable
  extend Gitlab::ConfigHelper
  extend ::Gitlab::Utils::Override

  # When updating this array, make sure to update rubocop/cop/gitlab/feature_available_usage.rb as well.
  FEATURES = %i[
    issues
    forking
    merge_requests
    wiki
    snippets
    builds
    repository
    pages
    metrics_dashboard
    analytics
    operations
    security_and_compliance
    container_registry
    package_registry
    environments
  ].freeze

  EXPORTABLE_FEATURES = (FEATURES - [:security_and_compliance, :pages]).freeze

  set_available_features(FEATURES)

  PRIVATE_FEATURES_MIN_ACCESS_LEVEL = {
    merge_requests: Gitlab::Access::REPORTER,
    metrics_dashboard: Gitlab::Access::REPORTER,
    container_registry: Gitlab::Access::REPORTER,
    package_registry: Gitlab::Access::REPORTER
  }.freeze
  PRIVATE_FEATURES_MIN_ACCESS_LEVEL_FOR_PRIVATE_PROJECT = { repository: Gitlab::Access::REPORTER }.freeze

  class << self
    def required_minimum_access_level(feature)
      feature = ensure_feature!(feature)

      PRIVATE_FEATURES_MIN_ACCESS_LEVEL.fetch(feature, Gitlab::Access::GUEST)
    end

    # Guest users can perform certain features on public and internal projects, but not private projects.
    def required_minimum_access_level_for_private_project(feature)
      feature = ensure_feature!(feature)

      PRIVATE_FEATURES_MIN_ACCESS_LEVEL_FOR_PRIVATE_PROJECT.fetch(feature) do
        required_minimum_access_level(feature)
      end
    end
  end

  belongs_to :project

  validates :project, presence: true

  validate :repository_children_level

  default_value_for :builds_access_level, value: ENABLED, allows_nil: false
  default_value_for :issues_access_level, value: ENABLED, allows_nil: false
  default_value_for :forking_access_level, value: ENABLED, allows_nil: false
  default_value_for :merge_requests_access_level, value: ENABLED, allows_nil: false
  default_value_for :snippets_access_level, value: ENABLED, allows_nil: false
  default_value_for :wiki_access_level, value: ENABLED, allows_nil: false
  default_value_for :repository_access_level, value: ENABLED, allows_nil: false
  default_value_for :analytics_access_level, value: ENABLED, allows_nil: false
  default_value_for :metrics_dashboard_access_level, value: PRIVATE, allows_nil: false
  default_value_for :operations_access_level, value: ENABLED, allows_nil: false
  default_value_for :security_and_compliance_access_level, value: PRIVATE, allows_nil: false
  default_value_for :monitor_access_level, value: ENABLED, allows_nil: false
  default_value_for :infrastructure_access_level, value: ENABLED, allows_nil: false
  default_value_for :feature_flags_access_level, value: ENABLED, allows_nil: false
  default_value_for :environments_access_level, value: ENABLED, allows_nil: false
  default_value_for :releases_access_level, value: ENABLED, allows_nil: false

  default_value_for(:pages_access_level, allows_nil: false) do |feature|
    if ::Gitlab::Pages.access_control_is_forced?
      PRIVATE
    else
      feature.project&.public? ? ENABLED : PRIVATE
    end
  end

  default_value_for(:package_registry_access_level) do |feature|
    if ::Gitlab.config.packages.enabled
      ENABLED
    else
      DISABLED
    end
  end

  default_value_for(:container_registry_access_level) do |feature|
    if gitlab_config_features.container_registry
      ENABLED
    else
      DISABLED
    end
  end

  # "enabled" here means "not disabled". It includes private features!
  scope :with_feature_enabled, ->(feature) {
    feature_access_level_attribute = arel_table[access_level_attribute(feature)]
    enabled_feature = feature_access_level_attribute.gt(DISABLED).or(feature_access_level_attribute.eq(nil))

    where(enabled_feature)
  }

  # Picks a feature where the level is exactly that given.
  scope :with_feature_access_level, ->(feature, level) {
    feature_access_level_attribute = access_level_attribute(feature)
    where(project_features: { feature_access_level_attribute => level })
  }

  # project features may be "disabled", "internal", "enabled" or "public". If "internal",
  # they are only available to team members. This scope returns features where
  # the feature is either public, enabled, or internal with permission for the user.
  # Note: this scope doesn't enforce that the user has access to the projects, it just checks
  # that the user has access to the feature. It's important to use this scope with others
  # that checks project authorizations first (e.g. `filter_by_feature_visibility`).
  #
  # This method uses an optimized version of `with_feature_access_level` for
  # logged in users to more efficiently get private projects with the given
  # feature.
  def self.with_feature_available_for_user(feature, user)
    visible = [ENABLED, PUBLIC]

    if user&.can_read_all_resources?
      with_feature_enabled(feature)
    elsif user
      min_access_level = required_minimum_access_level(feature)
      column = quoted_access_level_column(feature)

      where("#{column} IS NULL OR #{column} IN (:public_visible) OR (#{column} = :private_visible AND EXISTS (:authorizations))",
           {
             public_visible: visible,
             private_visible: PRIVATE,
             authorizations: user.authorizations_for_projects(min_access_level: min_access_level, related_project_column: 'project_features.project_id')
           })
    else
      # This has to be added to include features whose value is nil in the db
      visible << nil
      with_feature_access_level(feature, visible)
    end
  end

  def public_pages?
    return true unless Gitlab.config.pages.access_control

    return false if ::Gitlab::Pages.access_control_is_forced?

    pages_access_level == PUBLIC || pages_access_level == ENABLED && project.public?
  end

  def private_pages?
    !public_pages?
  end

  def package_registry_access_level=(value)
    super(value).tap do
      project.packages_enabled = self.package_registry_access_level != DISABLED if project
    end
  end

  private

  # Validates builds and merge requests access level
  # which cannot be higher than repository access level
  def repository_children_level
    validator = lambda do |field|
      level = public_send(field) || ENABLED # rubocop:disable GitlabSecurity/PublicSend
      not_allowed = level > repository_access_level
      self.errors.add(field, "cannot have higher visibility level than repository access level") if not_allowed
    end

    %i(merge_requests_access_level builds_access_level).each(&validator)
  end

  def feature_validation_exclusion
    %i(pages package_registry)
  end

  override :resource_member?
  def resource_member?(user, feature)
    project.team.member?(user, ProjectFeature.required_minimum_access_level(feature))
  end
end

ProjectFeature.prepend_mod_with('ProjectFeature')
