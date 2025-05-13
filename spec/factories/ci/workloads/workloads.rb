# frozen_string_literal: true

FactoryBot.define do
  factory :ci_workload, class: 'Ci::Workloads::Workload' do
    project { pipeline.project }
    pipeline factory: :ci_pipeline
  end
end
