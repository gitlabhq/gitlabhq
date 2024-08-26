# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_variable, class: 'Ci::JobVariable' do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value { 'VARIABLE_VALUE' }

    job factory: :ci_build

    trait :dotenv_source do
      source { :dotenv }
    end

    project_id { job.project.id }
  end
end
