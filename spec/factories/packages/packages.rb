# frozen_string_literal: true

FactoryBot.define do
  factory :package, class: 'Packages::Package' do
    project
    creator { project&.creator }
    name { 'my/company/app/my-app' }
    sequence(:version) { |n| "1.#{n}-SNAPSHOT" }
    package_type { :maven }
    status { :default }

    trait :hidden do
      status { :hidden }
    end

    trait :processing do
      status { :processing }
    end

    trait :error do
      status { :error }
    end

    trait :pending_destruction do
      status { :pending_destruction }
    end

    trait :last_downloaded_at do
      last_downloaded_at { 2.days.ago }
    end

    factory :maven_package do
      maven_metadatum

      after :build do |package|
        package.maven_metadatum.path = package.version? ? "#{package.name}/#{package.version}" : package.name
      end

      after :create do |package|
        create :package_file, :xml, package: package
        create :package_file, :jar, package: package
        create :package_file, :pom, package: package
      end
    end

    factory :npm_package do
      sequence(:name) { |n| "@#{project.root_namespace.path}/package-#{n}" }
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :npm }

      after :create do |package|
        create :package_file, :npm, package: package
      end

      trait :with_build do
        after :create do |package|
          user = package.project.creator
          pipeline = create(:ci_pipeline, user: user)
          create(:ci_build, user: user, pipeline: pipeline)
          create :package_build_info, package: package, pipeline: pipeline
        end
      end
    end

    factory :terraform_module_package do
      sequence(:name) { |n| "module-#{n}/system" }
      version { '1.0.0' }
      package_type { :terraform_module }

      transient do
        without_package_files { false }
      end

      after :create do |package, evaluator|
        unless evaluator.without_package_files
          create :package_file, :terraform_module, package: package
        end
      end

      trait :with_build do
        after :create do |package|
          user = package.project.creator
          pipeline = create(:ci_pipeline, user: user)
          create(:ci_build, user: user, pipeline: pipeline)
          create :package_build_info, package: package, pipeline: pipeline
        end
      end
    end

    factory :nuget_package do
      sequence(:name) { |n| "NugetPackage#{n}" }
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :nuget }

      transient do
        without_package_files { false }
      end

      after :create do |package, evaluator|
        unless evaluator.without_package_files
          create :package_file, :nuget, package: package, file_name: "#{package.name}.#{package.version}.nupkg"
        end
      end

      trait(:with_metadatum) do
        after :build do |pkg|
          pkg.nuget_metadatum = build(:nuget_metadatum)
        end
      end

      trait(:with_symbol_package) do
        after :create do |package|
          create :package_file, :snupkg, package: package, file_name: "#{package.name}.#{package.version}.snupkg"
        end
      end

      trait :with_build do
        after :create do |package|
          create(:package_build_info, package: package)
        end
      end
    end

    factory :pypi_package do
      sequence(:name) { |n| "pypi-package-#{n}" }
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :pypi }

      transient do
        without_loaded_metadatum { false }
      end

      after :create do |package, evaluator|
        create :package_file, :pypi, package: package, file_name: "#{package.name}-#{package.version}.tar.gz"

        unless evaluator.without_loaded_metadatum
          create :pypi_metadatum, package: package
        end
      end
    end

    # TODO: Remove with the rollout of the FF generic_extract_generic_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/479933
    factory :generic_package_legacy do
      sequence(:name) { |n| "generic-package-#{n}" }
      version { '1.0.0' }
      package_type { :generic }

      trait(:with_zip_file) do
        after :create do |package|
          create :package_file, :generic_zip, package: package
        end
      end
    end

    factory :ml_model_package, class: 'Packages::MlModel::Package' do
      sequence(:name) { |n| "mlmodel-package-#{n}" }
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :ml_model }
    end
  end
end
