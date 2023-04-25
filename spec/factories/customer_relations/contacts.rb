# frozen_string_literal: true

FactoryBot.define do
  factory :contact, class: 'CustomerRelations::Contact' do
    group

    first_name { generate(:name) }
    last_name { generate(:name) }
    email { generate(:email) }

    trait :inactive do
      state { :inactive }
    end
  end
end
