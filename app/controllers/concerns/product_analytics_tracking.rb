# frozen_string_literal: true

module ProductAnalyticsTracking
  include Gitlab::Tracking::Helpers
  include RedisTracking
  extend ActiveSupport::Concern

  MIGRATED_EVENTS = %w[
    g_analytics_valuestream
    i_search_paid
    i_search_total
    i_search_advanced
    i_ecosystem_jira_service_list_issues
    users_viewing_analytics_group_devops_adoption
    i_analytics_dev_ops_adoption
    i_analytics_dev_ops_score
    p_analytics_merge_request
    i_analytics_instance_statistics
    g_analytics_contribution
    p_analytics_pipelines
    p_analytics_code_reviews
    p_analytics_valuestream
    p_analytics_insights
    p_analytics_issues
    p_analytics_repo
    g_analytics_insights
    g_analytics_issues
    g_analytics_productivity
    i_analytics_cohorts
  ].freeze

  class_methods do
    def track_event(*controller_actions, name:, action: nil, label: nil, conditions: nil, destinations: [:redis_hll], &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_events_to(destinations, name, action, label, &block)
      end
    end
  end

  private

  def route_events_to(destinations, name, action, label, &block)
    track_unique_redis_hll_event(name, &block) if destinations.include?(:redis_hll)

    return unless destinations.include?(:snowplow) && event_enabled?(name)
    raise "action is required when destination is snowplow" unless action
    raise "label is required when destination is snowplow" unless label

    optional_arguments = {
      namespace: tracking_namespace_source,
      project: tracking_project_source
    }.compact

    Gitlab::Tracking.event(
      self.class.to_s,
      action,
      user: current_user,
      property: name,
      label: label,
      context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: name).to_context],
      **optional_arguments
    )
  end

  def event_enabled?(event)
    return true if MIGRATED_EVENTS.include?(event)

    events_to_ff = {
      g_edit_by_sfe: :_phase4,
      g_compliance_dashboard: :_phase4,
      g_compliance_audit_events: :_phase4,
      i_compliance_audit_events: :_phase4,
      i_compliance_credential_inventory: :_phase4
    }

    Feature.enabled?("route_hll_to_snowplow#{events_to_ff[event.to_sym]}", tracking_namespace_source)
  end
end
