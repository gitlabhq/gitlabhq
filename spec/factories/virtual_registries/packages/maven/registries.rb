# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_registries_packages_maven_registry, class: 'VirtualRegistries::Packages::Maven::Registry' do
    group

    trait :with_upstream do
      upstream { association(:virtual_registries_packages_maven_upstream, group: group) }
    end
  end
end
