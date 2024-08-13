# frozen_string_literal: true

FactoryBot.define do
  factory :ci_tag, class: 'Ci::Tag' do
    name { generate(:name) }
  end
end
