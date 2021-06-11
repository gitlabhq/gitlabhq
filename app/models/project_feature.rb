# frozen_string_literal: true

class ProjectFeature < ApplicationRecord
  include Featurable

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
  ].freeze

  EXPORTABLE_FEATURES = (FEATURES - [:security_and_compliance, :pages]).freeze

  set_available_features(FEATURES)

  PRIVATE_FEATURES_MIN_ACCESS_LEVEL = {
    merge_requests: Gitlab::Access::REPORTER,
    metrics_dashboard: Gitlab::Access::REPORTER,
    container_registry: Gitlab::Access::REPORTER
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

  before_create :set_container_registry_access_level

  # Default scopes force us to unscope here since a service may need to check
  # permissions for a project in pending_delete
  # http://stackoverflow.com/questions/1540645/how-to-disable-default-scope-for-a-belongs-to
  belongs_to :project, -> { unscope(where: :pending_delete) }

  validates :project, presence: true

  validate :repository_children_level
  validate :allowed_access_levels

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

  default_value_for(:pages_access_level, allows_nil: false) do |feature|
    if ::Gitlab::Pages.access_control_is_forced?
      PRIVATE
    else
      feature.project&.public? ? ENABLED : PRIVATE
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

  private

  def set_container_registry_access_level
    self.container_registry_access_level =
      if project&.read_attribute(:container_registry_enabled)
        ENABLED
      else
        DISABLED
      end
  end

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

  # Validates access level for other than pages cannot be PUBLIC
  def allowed_access_levels
    validator = lambda do |field|
      level = public_send(field) || ENABLED # rubocop:disable GitlabSecurity/PublicSend
      not_allowed = level > ENABLED
      self.errors.add(field, "cannot have public visibility level") if not_allowed
    end

    (FEATURES - %i(pages)).each {|f| validator.call("#{f}_access_level")}
  end

  def get_permission(user, feature)
    case access_level(feature)
    when DISABLED
      false
    when PRIVATE
      team_access?(user, feature)
    when ENABLED
      true
    when PUBLIC
      true
    else
      true
    end
  end

  def team_access?(user, feature)
    return unless user
    return true if user.can_read_all_resources?

    project.team.member?(user, ProjectFeature.required_minimum_access_level(feature))
  end
end

ProjectFeature.prepend_mod_with('ProjectFeature')
