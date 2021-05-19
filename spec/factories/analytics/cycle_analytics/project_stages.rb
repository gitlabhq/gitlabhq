# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_project_stage, class: 'Analytics::CycleAnalytics::ProjectStage' do
    project
    sequence(:name) { |n| "Stage ##{n}" }
    hidden { false }
    issue_stage
    value_stream { association(:cycle_analytics_project_value_stream, project: project) }

    trait :issue_stage do
      start_event_identifier { Gitlab::Analytics::CycleAnalytics::StageEvents::IssueCreated.identifier }
      end_event_identifier { Gitlab::Analytics::CycleAnalytics::StageEvents::IssueStageEnd.identifier }
    end
  end
end
