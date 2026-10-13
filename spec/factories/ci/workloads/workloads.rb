# frozen_string_literal: true

FactoryBot.define do
  factory :ci_workload, class: 'Ci::Workloads::Workload' do
    pipeline { association(:ci_pipeline, **@overrides.slice(:project).compact) }
    project { pipeline.project }

    before(:create) do |workload|
      workload.partition_id = workload.pipeline.partition_id
    end
  end
end
