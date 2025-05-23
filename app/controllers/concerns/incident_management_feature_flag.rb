# frozen_string_literal: true

module IncidentManagementFeatureFlag
  extend ActiveSupport::Concern

  private

  def check_incidents_feature_flag
    return unless Feature.enabled?(:hide_incident_management_features, project)

    handle_feature_flag_enabled_response
  end

  def handle_feature_flag_enabled_response
    render_404
  end
end
