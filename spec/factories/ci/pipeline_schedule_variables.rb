# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_schedule_variable, class: 'Ci::PipelineScheduleVariable' do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value { 'VARIABLE_VALUE' }
    variable_type { 'env_var' }

    pipeline_schedule factory: :ci_pipeline_schedule
  end
end
