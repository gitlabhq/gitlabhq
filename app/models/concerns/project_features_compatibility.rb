# frozen_string_literal: true

# Makes api V4 compatible with old project features permissions methods
#
# After migrating issues_enabled merge_requests_enabled builds_enabled snippets_enabled and wiki_enabled
# fields to a new table "project_features", support for the old fields is still needed in the API.
require 'gitlab/utils/all'

module ProjectFeaturesCompatibility
  extend ActiveSupport::Concern

  # TODO: remove in API v5, replaced by *_access_level
  def wiki_enabled=(value)
    write_feature_attribute_boolean(:wiki_access_level, value)
  end

  # TODO: remove in API v5, replaced by *_access_level
  def builds_enabled=(value)
    write_feature_attribute_boolean(:builds_access_level, value)
  end

  # TODO: remove in API v5, replaced by *_access_level
  def merge_requests_enabled=(value)
    write_feature_attribute_boolean(:merge_requests_access_level, value)
  end

  # TODO: remove in API v5, replaced by *_access_level
  def issues_enabled=(value)
    write_feature_attribute_boolean(:issues_access_level, value)
  end

  # TODO: remove in API v5, replaced by *_access_level
  def snippets_enabled=(value)
    write_feature_attribute_boolean(:snippets_access_level, value)
  end

  def security_and_compliance_enabled=(value)
    write_feature_attribute_boolean(:security_and_compliance_access_level, value)
  end

  def repository_access_level=(value)
    write_feature_attribute_string(:repository_access_level, value)
  end

  def wiki_access_level=(value)
    write_feature_attribute_string(:wiki_access_level, value)
  end

  def builds_access_level=(value)
    write_feature_attribute_string(:builds_access_level, value)
  end

  def merge_requests_access_level=(value)
    write_feature_attribute_string(:merge_requests_access_level, value)
  end

  def forking_access_level=(value)
    write_feature_attribute_string(:forking_access_level, value)
  end

  def issues_access_level=(value)
    write_feature_attribute_string(:issues_access_level, value)
  end

  def snippets_access_level=(value)
    write_feature_attribute_string(:snippets_access_level, value)
  end

  def package_registry_access_level=(value)
    write_feature_attribute_string(:package_registry_access_level, value)
  end

  def pages_access_level=(value)
    write_feature_attribute_string(:pages_access_level, value)
  end

  def metrics_dashboard_access_level=(value)
    write_feature_attribute_string(:metrics_dashboard_access_level, value)
  end

  def analytics_access_level=(value)
    write_feature_attribute_string(:analytics_access_level, value)
  end

  def operations_access_level=(value)
    write_feature_attribute_string(:operations_access_level, value)
  end

  def monitor_access_level=(value)
    write_feature_attribute_string(:monitor_access_level, value)
  end

  def security_and_compliance_access_level=(value)
    write_feature_attribute_string(:security_and_compliance_access_level, value)
  end

  def container_registry_access_level=(value)
    write_feature_attribute_string(:container_registry_access_level, value)
  end

  def environments_access_level=(value)
    write_feature_attribute_string(:environments_access_level, value)
  end

  def feature_flags_access_level=(value)
    write_feature_attribute_string(:feature_flags_access_level, value)
  end

  def releases_access_level=(value)
    write_feature_attribute_string(:releases_access_level, value)
  end

  def infrastructure_access_level=(value)
    write_feature_attribute_string(:infrastructure_access_level, value)
  end

  def model_experiments_access_level=(value)
    write_feature_attribute_string(:model_experiments_access_level, value)
  end

  def model_registry_access_level=(value)
    write_feature_attribute_string(:model_registry_access_level, value)
  end

  # TODO: Remove this method after we drop support for project create/edit APIs to set the
  # container_registry_enabled attribute. They can instead set the container_registry_access_level
  # attribute.
  def container_registry_enabled=(value)
    write_feature_attribute_boolean(:container_registry_access_level, value)
  end

  private

  def write_feature_attribute_boolean(field, value)
    value_type = Gitlab::Utils.to_boolean(value)
    if value_type.in?([true, false])
      access_level = value_type ? ProjectFeature::ENABLED : ProjectFeature::DISABLED
      write_feature_attribute_raw(field, access_level)
    else
      write_feature_attribute_string(field, value)
    end
  end

  def write_feature_attribute_string(field, value)
    access_level = ProjectFeature.access_level_from_str(value)
    write_feature_attribute_raw(field, access_level)
  end

  def write_feature_attribute_raw(field, value)
    build_project_feature unless project_feature

    project_feature.__send__(:write_attribute, field, value) # rubocop:disable GitlabSecurity/PublicSend
  end
end

ProjectFeaturesCompatibility.prepend_mod_with('ProjectFeaturesCompatibility')
