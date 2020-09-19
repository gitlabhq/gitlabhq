# frozen_string_literal: true

FactoryBot.define do
  factory :plan_limits do
    plan

    trait :default_plan do
      plan factory: :default_plan
    end

    trait :with_package_file_sizes do
      conan_max_file_size { 100 }
      maven_max_file_size { 100 }
      npm_max_file_size { 100 }
      nuget_max_file_size { 100 }
      pypi_max_file_size { 100 }
      generic_packages_max_file_size { 100 }
    end
  end
end
