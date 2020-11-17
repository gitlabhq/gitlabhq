# frozen_string_literal: true
FactoryBot.define do
  factory :package, class: 'Packages::Package' do
    project
    creator { project&.creator }
    name { 'my/company/app/my-app' }
    sequence(:version) { |n| "1.#{n}-SNAPSHOT" }
    package_type { :maven }

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

    factory :debian_package do
      package_type { :debian }
    end

    factory :npm_package do
      sequence(:name) { |n| "@#{project.root_namespace.path}/package-#{n}"}
      version { '1.0.0' }
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

    factory :nuget_package do
      sequence(:name) { |n| "NugetPackage#{n}"}
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :nuget }

      after :create do |package|
        create :package_file, :nuget, package: package, file_name: "#{package.name}.#{package.version}.nupkg"
      end

      trait(:with_metadatum) do
        after :build do |pkg|
          pkg.nuget_metadatum = build(:nuget_metadatum)
        end
      end
    end

    factory :pypi_package do
      sequence(:name) { |n| "pypi-package-#{n}"}
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

    factory :composer_package do
      sequence(:name) { |n| "composer-package-#{n}"}
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :composer }

      transient do
        sha { project.repository.find_branch('master').target }
        json { { name: name, version: version } }
      end

      trait(:with_metadatum) do
        after :create do |package, evaluator|
          create :composer_metadatum, package: package, target_sha: evaluator.sha, composer_json: evaluator.json
        end
      end
    end

    factory :golang_package do
      sequence(:name) { |n| "golang.org/x/pkg-#{n}"}
      sequence(:version) { |n| "v1.0.#{n}" }
      package_type { :golang }
    end

    factory :conan_package do
      conan_metadatum

      transient do
        without_package_files { false }
      end

      after :build do |package|
        package.conan_metadatum.package_username = Packages::Conan::Metadatum.package_username_from(
          full_path: package.project.full_path
        )
      end

      sequence(:name) { |n| "package-#{n}" }
      version { '1.0.0' }
      package_type { :conan }

      after :create do |package, evaluator|
        unless evaluator.without_package_files
          create :conan_package_file, :conan_recipe_file, package: package
          create :conan_package_file, :conan_recipe_manifest, package: package
          create :conan_package_file, :conan_package_info, package: package
          create :conan_package_file, :conan_package_manifest, package: package
          create :conan_package_file, :conan_package, package: package
        end
      end

      trait(:without_loaded_metadatum) do
        conan_metadatum { build(:conan_metadatum, package: nil) } # rubocop:disable FactoryBot/InlineAssociation
      end
    end

    factory :generic_package do
      sequence(:name) { |n| "generic-package-#{n}" }
      version { '1.0.0' }
      package_type { :generic }
    end
  end

  factory :composer_metadatum, class: 'Packages::Composer::Metadatum' do
    package { association(:composer_package) }

    target_sha { '123' }
    composer_json { { name: 'foo' } }
  end

  factory :maven_metadatum, class: 'Packages::Maven::Metadatum' do
    association :package, package_type: :maven
    path { 'my/company/app/my-app/1.0-SNAPSHOT' }
    app_group { 'my.company.app' }
    app_name { 'my-app' }
    app_version { '1.0-SNAPSHOT' }
  end

  factory :conan_metadatum, class: 'Packages::Conan::Metadatum' do
    association :package, factory: [:conan_package, :without_loaded_metadatum], without_package_files: true
    package_username { 'username' }
    package_channel { 'stable' }
  end

  factory :pypi_metadatum, class: 'Packages::Pypi::Metadatum' do
    package { association(:pypi_package, without_loaded_metadatum: true) }
    required_python { '>=2.7' }
  end

  factory :nuget_metadatum, class: 'Packages::Nuget::Metadatum' do
    package { association(:nuget_package) }

    license_url { 'http://www.gitlab.com' }
    project_url { 'http://www.gitlab.com' }
    icon_url { 'http://www.gitlab.com' }
  end

  factory :conan_file_metadatum, class: 'Packages::Conan::FileMetadatum' do
    package_file { association(:conan_package_file, :conan_recipe_file, without_loaded_metadatum: true) }
    recipe_revision { '0' }
    conan_file_type { 'recipe_file' }

    trait(:recipe_file) do
      conan_file_type { 'recipe_file' }
    end

    trait(:package_file) do
      package_file { association(:conan_package_file, :conan_package, without_loaded_metadatum: true) }
      conan_file_type { 'package_file' }
      package_revision { '0' }
      conan_package_reference { '123456789' }
    end
  end

  factory :packages_dependency, class: 'Packages::Dependency' do
    sequence(:name) { |n| "@test/package-#{n}"}
    sequence(:version_pattern) { |n| "~6.2.#{n}" }
  end

  factory :packages_dependency_link, class: 'Packages::DependencyLink' do
    package { association(:nuget_package) }
    dependency { association(:packages_dependency) }
    dependency_type { :dependencies }

    trait(:with_nuget_metadatum) do
      after :build do |link|
        link.nuget_metadatum = build(:nuget_dependency_link_metadatum)
      end
    end
  end

  factory :nuget_dependency_link_metadatum, class: 'Packages::Nuget::DependencyLinkMetadatum' do
    dependency_link { association(:packages_dependency_link) }
    target_framework { '.NETStandard2.0' }
  end

  factory :packages_tag, class: 'Packages::Tag' do
    package
    sequence(:name) { |n| "tag-#{n}"}
  end
end
