# frozen_string_literal: true

# This module represents the default Value Stream Analytics stages that are currently provided by CE
# Each method returns a hash that can be used to build a new stage object.
#
# Example:
#
# params = Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_issue_stage
# Analytics::CycleAnalytics::Stage.new(params)
module Gitlab
  module Analytics
    module CycleAnalytics
      module DefaultStages
        def self.all
          [
            params_for_issue_stage,
            params_for_plan_stage,
            params_for_code_stage,
            params_for_test_stage,
            params_for_review_stage,
            params_for_staging_stage
          ]
        end

        def self.find_by_name!(name)
          find_by_name(name) || raise("Default stage '#{name}' not found")
        end

        def self.find_by_name(name)
          all.find { |raw_stage| raw_stage[:name].to_s.eql?(name.to_s) }
        end

        def self.names
          all.map { |stage| stage[:name] }
        end

        def self.symbolized_stage_names
          names.map(&:to_sym)
        end

        def self.params_for_issue_stage
          {
            name: 'issue',
            custom: false, # this stage won't be customizable, we provide it as it is
            relative_position: 1, # when opening the CycleAnalytics page in CE, this stage will be the first item
            start_event_identifier: :issue_created, # IssueCreated class is used as start event
            end_event_identifier: :issue_stage_end # IssueStageEnd class is used as end event
          }
        end

        def self.params_for_plan_stage
          {
            name: 'plan',
            custom: false,
            relative_position: 2,
            start_event_identifier: :plan_stage_start,
            end_event_identifier: :issue_first_mentioned_in_commit
          }
        end

        def self.params_for_code_stage
          {
            name: 'code',
            custom: false,
            relative_position: 3,
            start_event_identifier: :code_stage_start,
            end_event_identifier: :merge_request_created
          }
        end

        def self.params_for_test_stage
          {
            name: 'test',
            custom: false,
            relative_position: 4,
            start_event_identifier: :merge_request_last_build_started,
            end_event_identifier: :merge_request_last_build_finished
          }
        end

        def self.params_for_review_stage
          {
            name: 'review',
            custom: false,
            relative_position: 5,
            start_event_identifier: :merge_request_created,
            end_event_identifier: :merge_request_merged
          }
        end

        def self.params_for_staging_stage
          {
            name: 'staging',
            custom: false,
            relative_position: 6,
            start_event_identifier: :merge_request_merged,
            end_event_identifier: :merge_request_first_deployed_to_production
          }
        end
      end
    end
  end
end
