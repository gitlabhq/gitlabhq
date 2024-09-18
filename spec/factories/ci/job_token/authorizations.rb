# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_token_authorization, class: 'Ci::JobToken::Authorization' do
    association :origin_project, factory: :project
    association :accessed_project, factory: :project
    last_authorized_at { Time.current }
  end
end
