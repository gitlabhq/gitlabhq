# frozen_string_literal: true

FactoryBot.define do
  factory :npm_package, class: 'Packages::Npm::Package', parent: :package do
    sequence(:name) { |n| "@#{project.root_namespace.path}/package-#{n}" }
    sequence(:version) { |n| "1.0.#{n}" }
    package_type { :npm }

    package_files do
      [association(:package_file, :npm, package: instance)]
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
