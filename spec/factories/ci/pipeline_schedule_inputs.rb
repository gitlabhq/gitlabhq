# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_schedule_input, class: 'Ci::PipelineScheduleInput' do
    sequence(:name) { |n| "input_#{n}" }
    value { 'value' }

    pipeline_schedule factory: :ci_pipeline_schedule
    project { pipeline_schedule.project }
  end
end
