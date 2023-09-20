# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/users.html
    factory :user, class: 'QA::Resource::User' do
      trait :admin do
        admin { true }
      end

      trait :set_public_email do
        after(:create, &:set_public_email)
      end

      trait :hard_delete do
        hard_delete_on_api_removal { true }
      end
    end
  end
end
