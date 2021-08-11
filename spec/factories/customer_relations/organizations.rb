# frozen_string_literal: true

FactoryBot.define do
  factory :organization, class: 'CustomerRelations::Organization' do
    group

    name { generate(:name) }
  end
end
