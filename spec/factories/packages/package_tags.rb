# frozen_string_literal: true

FactoryBot.define do
  factory :packages_tag, class: 'Packages::Tag' do
    package { association(:generic_package) }
    sequence(:name) { |n| "tag-#{n}" }
  end
end
