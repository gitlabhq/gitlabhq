# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_token_project_scope_link, class: 'Ci::JobToken::ProjectScopeLink' do
    association :source_project, factory: :project
    association :target_project, factory: :project
    association :added_by, factory: :user
    job_token_policies { [] }
  end
end
