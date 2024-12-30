# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/users.html
    factory :user, class: 'QA::Resource::User' do
      trait :admin do
        is_admin { true }
      end

      trait :set_public_email do
        after(:create, &:set_public_email)
      end

      trait :hard_delete do
        hard_delete_on_api_removal { true }
      end

      trait :with_personal_access_token do
        with_personal_access_token { true }
      end
    end

    # https://docs.gitlab.com/ee/api/members.html
    factory :project_member, class: 'QA::Resource::ProjectMember' do
      trait :guest do
        access_level { 10 }
      end

      trait :reporter do
        access_level { 20 }
      end

      trait :developer do
        access_level { 30 }
      end

      trait :maintainer do
        access_level { 40 }
      end

      trait :owner do
        access_level { 50 }
      end
    end
  end
end
