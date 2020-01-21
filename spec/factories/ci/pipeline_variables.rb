# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_variable, class: 'Ci::PipelineVariable' do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value { 'VARIABLE_VALUE' }

    pipeline factory: :ci_empty_pipeline
  end
end
