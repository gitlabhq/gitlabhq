# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_definition_instance, class: 'Ci::JobDefinitionInstance' do
    project factory: :project
    job factory: :ci_build
    job_definition factory: :ci_job_definition
  end
end
