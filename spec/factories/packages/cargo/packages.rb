# frozen_string_literal: true

FactoryBot.define do
  factory :cargo_package, class: 'Packages::Cargo::Package', parent: :package do
    sequence(:name) { |n| "cargo-package-#{n}" }
    sequence(:version) { |n| "1.0.#{n}" }
    package_type { :cargo }

    trait :with_metadatum do
      cargo_metadatum { association(:cargo_metadatum, package: instance) }
    end
  end
end
