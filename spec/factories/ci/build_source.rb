# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_source, class: 'Ci::BuildSource' do
    job factory: :ci_build, scheduling_type: :dag
    project_id { job.project_id }
    source { :scan_execution_policy }
  end
end
