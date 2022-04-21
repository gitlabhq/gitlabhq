# frozen_string_literal: true

FactoryBot.define do
  factory :topic, class: 'Projects::Topic' do
    name { generate(:name) }
    title { generate(:title) }
  end
end
