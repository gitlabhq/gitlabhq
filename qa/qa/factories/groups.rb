# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :group_base, class: 'QA::Resource::GroupBase' do
      trait :private do
        visibility { :private }
      end

      trait :require_2fa do
        require_two_factor_authentication { true }
      end

      factory :sandbox, class: 'QA::Resource::Sandbox'
      factory :group, class: 'QA::Resource::Group'
    end
  end
end
