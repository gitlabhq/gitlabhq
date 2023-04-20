# frozen_string_literal: true

module Enums
  module InternalId
    def self.usage_resources
      # when adding new resource, make sure it doesn't conflict with EE usage_resources
      {
        issues: 0,
        merge_requests: 1,
        deployments: 2,
        milestones: 3,
        epics: 4,
        ci_pipelines: 5,
        operations_feature_flags: 6,
        operations_user_lists: 7,
        alert_management_alerts: 8,
        sprints: 9, # iterations
        design_management_designs: 10,
        incident_management_oncall_schedules: 11,
        ml_experiments: 12,
        ml_candidates: 13
      }
    end
  end
end

Enums::InternalId.prepend_mod_with('Enums::InternalId')
