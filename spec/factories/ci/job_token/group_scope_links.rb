# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_token_group_scope_link, class: 'Ci::JobToken::GroupScopeLink' do
    association :source_project, factory: :project
    association :target_group, factory: :group
    association :added_by, factory: :user
  end
end
