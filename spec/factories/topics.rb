# frozen_string_literal: true

FactoryBot.define do
  factory :topic, class: 'Projects::Topic' do
    name { generate(:name) }
  end
end
