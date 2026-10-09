# frozen_string_literal: true

FactoryBot.define do
  factory :ci_stage, class: 'Ci::Stage' do
    project { pipeline.project }
    pipeline { association(:ci_empty_pipeline, **@overrides.slice(:project).compact) }

    name { 'test' }
    position { 1 }
    status { 'pending' }
  end
end
