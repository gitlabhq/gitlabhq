# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlanLimitsHelper, feature_category: :continuous_integration do
  describe '#plan_limit_setting_description' do
    it 'describes known limits', :aggregate_failures do
      [
        :ci_instance_level_variables,
        :dotenv_size,
        :dotenv_variables,
        :ci_pipeline_size,
        :ci_active_jobs,
        :ci_project_subscriptions,
        :ci_pipeline_schedules,
        :ci_needs_size_limit,
        :ci_registered_group_runners,
        :ci_registered_project_runners,
        :pipeline_hierarchy_size
      ].each do |limit_name|
        expect(helper.plan_limit_setting_description(limit_name)).to be_present
      end
    end

    it 'raises an ArgumentError on invalid arguments' do
      expect { helper.plan_limit_setting_description(:some_invalid_limit) }.to(
        raise_error(ArgumentError, /No description/)
      )
    end
  end
end
