# frozen_string_literal: true

FactoryBot.define do
  factory :packages_dependency, class: 'Packages::Dependency' do
    sequence(:name) { |n| "@test/package-#{n}" }
    sequence(:version_pattern) { |n| "~6.2.#{n}" }
    project

    trait(:rubygems) do
      sequence(:name) { |n| "gem-dependency-#{n}" }
    end
  end
end
