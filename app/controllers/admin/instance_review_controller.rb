# frozen_string_literal: true
class Admin::InstanceReviewController < Admin::ApplicationController
  feature_category :devops_reports

  urgency :low

  def index
    redirect_to("#{subscription_portal_instance_review_url}?#{instance_review_params}")
  end

  def instance_review_params
    result = {
      instance_review: {
        email: current_user.email,
        last_name: current_user.name,
        version: ::Gitlab::VERSION
      }
    }

    if Gitlab::CurrentSettings.usage_ping_enabled?
      data = Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values, cached: true)
      counts = data[:counts]

      result[:instance_review].merge!(
        users_count: data[:active_user_count],
        projects_count: counts[:projects],
        groups_count: counts[:groups],
        issues_count: counts[:issues],
        merge_requests_count: counts[:merge_requests],
        internal_pipelines_count: counts[:ci_internal_pipelines],
        external_pipelines_count: counts[:ci_external_pipelines],
        labels_count: counts[:labels],
        milestones_count: counts[:milestones],
        snippets_count: counts[:snippets],
        notes_count: counts[:notes]
      )
    end

    result.to_query
  end
end
