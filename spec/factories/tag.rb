# frozen_string_literal: true

FactoryBot.define do
  factory :tag, class: 'ActsAsTaggableOn::Tag' do
    name { generate(:name) }
  end
end
