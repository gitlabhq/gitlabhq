# frozen_string_literal: true

FactoryBot.define do
  factory :protected_branch_push_access_level, class: 'ProtectedBranch::PushAccessLevel' do
    protected_branch
    deploy_key { nil }
    access_level { Gitlab::Access::DEVELOPER }
  end
end
