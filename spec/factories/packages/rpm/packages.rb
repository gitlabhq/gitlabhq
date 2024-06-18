# frozen_string_literal: true

FactoryBot.define do
  factory :rpm_package, class: 'Packages::Rpm::Package', parent: :package do
    sequence(:name) { |n| "package-#{n}" }
    sequence(:version) { |n| "v1.0.#{n}" }
    package_type { :rpm }
  end
end
