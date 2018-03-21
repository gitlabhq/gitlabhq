# Makes api V3 compatible with old project features permissions methods
#
# After migrating issues_enabled merge_requests_enabled builds_enabled snippets_enabled and wiki_enabled
# fields to a new table "project_features", support for the old fields is still needed in the API.
require 'gitlab/utils'

module ProjectFeaturesCompatibility
  extend ActiveSupport::Concern

  def wiki_enabled=(value)
    write_feature_attribute(:wiki_access_level, value)
  end

  def builds_enabled=(value)
    write_feature_attribute(:builds_access_level, value)
  end

  def merge_requests_enabled=(value)
    write_feature_attribute(:merge_requests_access_level, value)
  end

  def issues_enabled=(value)
    write_feature_attribute(:issues_access_level, value)
  end

  def snippets_enabled=(value)
    write_feature_attribute(:snippets_access_level, value)
  end

  private

  def write_feature_attribute(field, value)
    build_project_feature unless project_feature

    access_level = Gitlab::Utils.to_boolean(value) ? ProjectFeature::ENABLED : ProjectFeature::DISABLED
    project_feature.__send__(:write_attribute, field, access_level) # rubocop:disable GitlabSecurity/PublicSend
  end
end
