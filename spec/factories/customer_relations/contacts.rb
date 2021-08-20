# frozen_string_literal: true

FactoryBot.define do
  factory :contact, class: 'CustomerRelations::Contact' do
    group

    first_name { generate(:name) }
    last_name { generate(:name) }

    trait :with_organization do
      organization
    end
  end
end
