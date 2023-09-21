# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :ci_variable, class: 'QA::Resource::CiVariable' do
      trait :masked do
        masked { true }
      end

      trait :protected do
        protected { true }
      end
    end
  end
end
