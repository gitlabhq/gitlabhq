# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every metric definition', feature_category: :service_ping, unless: Gitlab.ee? do
  include_examples "every metric definition" do
    let(:ce_key_paths_mistakenly_defined_in_ee) do
      %w[
        counts.assignee_lists
        counts.milestone_lists
        counts.projects_with_repositories_enabled
        counts.protected_branches
      ].freeze
    end

    let(:ee_key_paths_mistakenly_defined_in_ce) do
      %w[
        counts.operations_dashboard_default_dashboard
        counts.operations_dashboard_users_with_projects_added
        usage_activity_by_stage.create.projects_imported_from_github
        usage_activity_by_stage.monitor.operations_dashboard_users_with_projects_added
        usage_activity_by_stage.plan.epics
        usage_activity_by_stage.plan.label_lists
        usage_activity_by_stage_monthly.create.projects_imported_from_github
        usage_activity_by_stage_monthly.create.protected_branches
        usage_activity_by_stage_monthly.monitor.operations_dashboard_users_with_projects_added
        usage_activity_by_stage_monthly.plan.epics
        usage_activity_by_stage_monthly.plan.label_lists
        usage_activity_by_stage_monthly.secure.sast_pipeline
        usage_activity_by_stage_monthly.secure.secret_detection_pipeline
      ].freeze
    end

    let(:expected_metric_files_key_paths) do
      metric_files_key_paths - ee_key_paths_mistakenly_defined_in_ce + ce_key_paths_mistakenly_defined_in_ee
    end
  end
end
