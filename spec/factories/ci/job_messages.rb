# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_message, class: 'Ci::JobMessage' do
    job factory: :ci_build
    content { 'The resulting pipeline would have been empty. Review the rules configuration for the relevant jobs.' }
    severity { :error }
    project_id { job.project_id }
  end
end
