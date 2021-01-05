# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_package_setting, class: 'Namespace::PackageSetting' do
    namespace

    maven_duplicates_allowed { true }
    maven_duplicate_exception_regex { 'SNAPSHOT' }

    trait :group do
      namespace { association(:group) }
    end
  end
end
