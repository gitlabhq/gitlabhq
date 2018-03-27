FactoryBot.define do
  factory :ci_pipeline_schedule_variable, class: Ci::PipelineScheduleVariable do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value 'VARIABLE_VALUE'

    pipeline_schedule factory: :ci_pipeline_schedule
  end
end
