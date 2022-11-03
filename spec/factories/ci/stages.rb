# frozen_string_literal: true

FactoryBot.define do
  factory :ci_stage, class: 'Ci::Stage' do
    project { pipeline.project }
    pipeline factory: :ci_empty_pipeline

    name { 'test' }
    position { 1 }
    status { 'pending' }
  end
end
