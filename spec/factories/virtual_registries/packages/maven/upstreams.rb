# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_registries_packages_maven_upstream, class: 'VirtualRegistries::Packages::Maven::Upstream' do
    url { 'http://local.test/maven' }
    username { 'user' }
    password { 'password' }
    registry { association(:virtual_registries_packages_maven_registry) }
    group { registry.group }

    after(:build) do |entry, _|
      entry.registry_upstream.group = entry.group if entry.registry_upstream
    end
  end
end
