# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_module_package, class: 'Packages::TerraformModule::Package', parent: :package do
    sequence(:name) { |n| "module-#{n}/system" }
    version { '1.0.0' }
    package_type { :terraform_module }

    transient do
      without_package_files { false }
    end

    package_files do
      if without_package_files
        []
      else
        [association(:package_file, :terraform_module, package: instance)]
      end
    end

    trait :with_build do
      # rubocop:disable RSpec/FactoryBot/StrategyInCallback -- https://gitlab.com/gitlab-org/gitlab/-/issues/493949
      after :create do |package|
        user = package.project.creator
        pipeline = create(:ci_pipeline, user: user)
        create(:ci_build, user: user, pipeline: pipeline)
        create :package_build_info, package: package, pipeline: pipeline
      end
      # rubocop:enable RSpec/FactoryBot/StrategyInCallback
    end
  end
end
