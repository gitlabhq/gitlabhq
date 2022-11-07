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

    def track_custom_event(*controller_actions, name:, conditions: nil, action:, label:, destinations: [:redis_hll], &block)
      custom_conditions = [:trackable_html_request?, *conditions]

      after_action only: controller_actions, if: custom_conditions do
        route_custom_events_to(destinations, name, action, label, &block)
      end
    end
  end

  private

  def route_events_to(destinations, name, &block)
    track_unique_redis_hll_event(name, &block) if destinations.include?(:redis_hll)

    if destinations.include?(:snowplow) && event_enabled?(name)
      Gitlab::Tracking.event(
        self.class.to_s,
        name,
        namespace: tracking_namespace_source,
        user: current_user,
        context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: name).to_context]
      )
    end
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
      g_analytics_valuestream: :route_hll_to_snowplow,

      i_search_paid: :route_hll_to_snowplow_phase2,
      i_search_total: :route_hll_to_snowplow_phase2,
      i_search_advanced: :route_hll_to_snowplow_phase2,
      i_ecosystem_jira_service_list_issues: :route_hll_to_snowplow_phase2,
      users_viewing_analytics_group_devops_adoption: :route_hll_to_snowplow_phase2,
      i_analytics_dev_ops_adoption: :route_hll_to_snowplow_phase2,
      i_analytics_dev_ops_score: :route_hll_to_snowplow_phase2,
      p_analytics_merge_request: :route_hll_to_snowplow_phase2,
      i_analytics_instance_statistics: :route_hll_to_snowplow_phase2,
      g_analytics_contribution: :route_hll_to_snowplow_phase2,
      p_analytics_pipelines: :route_hll_to_snowplow_phase2,
      p_analytics_code_reviews: :route_hll_to_snowplow_phase2,
      p_analytics_valuestream: :route_hll_to_snowplow_phase2,
      p_analytics_insights: :route_hll_to_snowplow_phase2,
      p_analytics_issues: :route_hll_to_snowplow_phase2,
      p_analytics_repo: :route_hll_to_snowplow_phase2,
      g_analytics_insights: :route_hll_to_snowplow_phase2,
      g_analytics_issues: :route_hll_to_snowplow_phase2,
      g_analytics_productivity: :route_hll_to_snowplow_phase2,
      i_analytics_cohorts: :route_hll_to_snowplow_phase2
    }

    Feature.enabled?(events_to_ff[event.to_sym], tracking_namespace_source)
  end
end
