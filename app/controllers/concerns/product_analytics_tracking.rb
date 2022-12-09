# frozen_string_literal: true

module ProductAnalyticsTracking
  include Gitlab::Tracking::Helpers
  include RedisTracking
  extend ActiveSupport::Concern

  class_methods do
    # TODO: Remove once all the events are migrated to #track_custom_event
    # during https://gitlab.com/groups/gitlab-org/-/epics/8641
    def track_event(*controller_actions, name:, conditions: nil, destinations: [:redis_hll], &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_events_to(destinations, name, &block)
      end
    end

    def track_custom_event(*controller_actions, name:, action:, label:, conditions: nil, destinations: [:redis_hll], &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_custom_events_to(destinations, name, action, label, &block)
      end
    end
  end

  private

  def route_events_to(destinations, name, &block)
    track_unique_redis_hll_event(name, &block) if destinations.include?(:redis_hll)

    return unless destinations.include?(:snowplow) && event_enabled?(name)

    Gitlab::Tracking.event(
      self.class.to_s,
      name,
      namespace: tracking_namespace_source,
      user: current_user,
      context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: name).to_context]
    )
  end

  def route_custom_events_to(destinations, name, action, label, &block)
    track_unique_redis_hll_event(name, &block) if destinations.include?(:redis_hll)

    return unless destinations.include?(:snowplow) && event_enabled?(name)

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
    events_to_ff = {
      g_analytics_valuestream: '',

      i_search_paid: :_phase2,
      i_search_total: :_phase2,
      i_search_advanced: :_phase2,
      i_ecosystem_jira_service_list_issues: :_phase2,
      users_viewing_analytics_group_devops_adoption: :_phase2,
      i_analytics_dev_ops_adoption: :_phase2,
      i_analytics_dev_ops_score: :_phase2,
      p_analytics_merge_request: :_phase2,
      i_analytics_instance_statistics: :_phase2,
      g_analytics_contribution: :_phase2,
      p_analytics_pipelines: :_phase2,
      p_analytics_code_reviews: :_phase2,
      p_analytics_valuestream: :_phase2,
      p_analytics_insights: :_phase2,
      p_analytics_issues: :_phase2,
      p_analytics_repo: :_phase2,
      g_analytics_insights: :_phase2,
      g_analytics_issues: :_phase2,
      g_analytics_productivity: :_phase2,
      i_analytics_cohorts: :_phase2,

      g_compliance_dashboard: :_phase4
    }

    Feature.enabled?("route_hll_to_snowplow#{events_to_ff[event.to_sym]}", tracking_namespace_source)
  end
end
