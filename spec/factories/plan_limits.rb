# frozen_string_literal: true

FactoryBot.define do
  factory :plan_limits do
    plan
    plan_name_uid { Plan::PLAN_NAME_UID_LIST[:default] }

    dast_profile_schedules { 50 }

    Plan.all_plans.each do |plan_name|
      trait :"#{plan_name}_plan" do
        plan factory: :"#{plan_name}_plan"
        plan_name_uid { Plan::PLAN_NAME_UID_LIST[plan_name.to_sym] }
      end
    end

    trait :with_package_file_sizes do
      conan_max_file_size { 100 }
      helm_max_file_size { 100 }
      maven_max_file_size { 100 }
      npm_max_file_size { 100 }
      nuget_max_file_size { 100 }
      pypi_max_file_size { 100 }
      generic_packages_max_file_size { 100 }
    end
  end
end
