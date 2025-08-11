# frozen_string_literal: true

FactoryBot.define do
  factory :ci_workload_variable_inclusion, class: 'Ci::Workloads::VariableInclusions' do
    project { pipeline.project }
    workload factory: :ci_workload
    variable_name { "SOME_VAR" }
  end
end
