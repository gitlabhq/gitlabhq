# frozen_string_literal: true

FactoryBot.define do
  factory :ci_workload, class: 'Ci::Workloads::Workload' do
    pipeline factory: :ci_pipeline
    project { pipeline.project }

    before(:create) do |workload|
      workload.partition_id = workload.pipeline.partition_id
    end
  end
end
