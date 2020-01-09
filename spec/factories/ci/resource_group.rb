# frozen_string_literal: true

FactoryBot.define do
  factory :ci_resource_group, class: 'Ci::ResourceGroup' do
    project
    sequence(:key) { |n| "IOS_#{n}" }
  end
end
