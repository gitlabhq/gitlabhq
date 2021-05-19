# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_package_setting, class: 'Namespace::PackageSetting' do
    namespace

    maven_duplicates_allowed { true }
    maven_duplicate_exception_regex { 'SNAPSHOT' }

    generic_duplicates_allowed { true }
    generic_duplicate_exception_regex { 'foo' }

    trait :group do
      namespace { association(:group) }
    end
  end
end
