# frozen_string_literal: true
FactoryBot.define do
  factory :package, class: 'Packages::Package' do
    project
    name { 'my/company/app/my-app' }
    sequence(:version) { |n| "1.#{n}-SNAPSHOT" }
    package_type { :maven }

    factory :maven_package do
      maven_metadatum

      after :build do |package|
        package.maven_metadatum.path = "#{package.name}/#{package.version}"
      end

      after :create do |package|
        create :package_file, :xml, package: package
        create :package_file, :jar, package: package
        create :package_file, :pom, package: package
      end
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
      pypi_metadatum

      sequence(:name) { |n| "pypi-package-#{n}"}
      sequence(:version) { |n| "1.0.#{n}" }
      package_type { :pypi }

      after :create do |package|
        create :package_file, :pypi, package: package, file_name: "#{package.name}-#{package.version}.tar.gz"
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
        conan_metadatum { build(:conan_metadatum, package: nil) }
      end
    end
  end

  factory :composer_metadatum, class: 'Packages::Composer::Metadatum' do
    package { create(:composer_package) }

    target_sha { '123' }
    composer_json { { name: 'foo' } }
  end

  factory :package_build_info, class: 'Packages::BuildInfo' do
    package
  end

  factory :package_file, class: 'Packages::PackageFile' do
    package

    file_name { 'somefile.txt' }

    transient do
      file_fixture { 'spec/fixtures/packages/conan/recipe_files/conanfile.py' }
    end

    after(:build) do |package_file, evaluator|
      package_file.file = fixture_file_upload(evaluator.file_fixture)
    end

    factory :conan_package_file do
      package { create(:conan_package, without_package_files: true) }

      transient do
        without_loaded_metadatum { false }
      end

      trait(:conan_recipe_file) do
        after :create do |package_file, evaluator|
          unless evaluator.without_loaded_metadatum
            create :conan_file_metadatum, :recipe_file, package_file: package_file
          end
        end

        file_fixture { 'spec/fixtures/packages/conan/recipe_files/conanfile.py' }
        file_name { 'conanfile.py' }
        file_sha1 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }
        file_md5 { '12345abcde' }
        size { 400.kilobytes }
      end

      trait(:conan_recipe_manifest) do
        after :create do |package_file, evaluator|
          unless evaluator.without_loaded_metadatum
            create :conan_file_metadatum, :recipe_file, package_file: package_file
          end
        end

        file_fixture { 'spec/fixtures/packages/conan/recipe_files/conanmanifest.txt' }
        file_name { 'conanmanifest.txt' }
        file_sha1 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }
        file_md5 { '12345abcde' }
        size { 400.kilobytes }
      end

      trait(:conan_package_manifest) do
        after :create do |package_file, evaluator|
          unless evaluator.without_loaded_metadatum
            create :conan_file_metadatum, :package_file, package_file: package_file
          end
        end

        file_fixture { 'spec/fixtures/packages/conan/package_files/conanmanifest.txt' }
        file_name { 'conanmanifest.txt' }
        file_sha1 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }
        file_md5 { '12345abcde' }
        size { 400.kilobytes }
      end

      trait(:conan_package_info) do
        after :create do |package_file, evaluator|
          unless evaluator.without_loaded_metadatum
            create :conan_file_metadatum, :package_file, package_file: package_file
          end
        end

        file_fixture { 'spec/fixtures/packages/conan/package_files/conaninfo.txt' }
        file_name { 'conaninfo.txt' }
        file_sha1 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }
        file_md5 { '12345abcde' }
        size { 400.kilobytes }
      end

      trait(:conan_package) do
        after :create do |package_file, evaluator|
          unless evaluator.without_loaded_metadatum
            create :conan_file_metadatum, :package_file, package_file: package_file
          end
        end

        file_fixture { 'spec/fixtures/packages/conan/package_files/conan_package.tgz' }
        file_name { 'conan_package.tgz' }
        file_sha1 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }
        file_md5 { '12345abcde' }
        size { 400.kilobytes }
      end
    end

    trait(:jar) do
      file_fixture { 'spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.jar' }
      file_name { 'my-app-1.0-20180724.124855-1.jar' }
      file_sha1 { '4f0bfa298744d505383fbb57c554d4f5c12d88b3' }
      size { 100.kilobytes }
    end

    trait(:pom) do
      file_fixture { 'spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.pom' }
      file_name { 'my-app-1.0-20180724.124855-1.pom' }
      file_sha1 { '19c975abd49e5102ca6c74a619f21e0cf0351c57' }
      size { 200.kilobytes }
    end

    trait(:xml) do
      file_fixture { 'spec/fixtures/packages/maven/maven-metadata.xml' }
      file_name { 'maven-metadata.xml' }
      file_sha1 { '42b1bdc80de64953b6876f5a8c644f20204011b0' }
      size { 300.kilobytes }
    end

    trait(:npm) do
      file_fixture { 'spec/fixtures/packages/npm/foo-1.0.1.tgz' }
      file_name { 'foo-1.0.1.tgz' }
      file_sha1 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }
      verified_at { Date.current }
      verification_checksum { '4437b5775e61455588a7e5187a2e5c58c680694260bbe5501c235ec690d17f83' }
      size { 400.kilobytes }
    end

    trait(:nuget) do
      package
      file_fixture { 'spec/fixtures/packages/nuget/package.nupkg' }
      file_name { 'package.nupkg' }
      file_sha1 { '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57' }
      size { 300.kilobytes }
    end

    trait(:pypi) do
      package
      file_fixture { 'spec/fixtures/packages/pypi/sample-project.tar.gz' }
      file_name { 'sample-project-1.0.0.tar.gz' }
      file_sha1 { '2c0cfbed075d3fae226f051f0cc771b533e01aff' }
      file_md5 { '0a7392d24f42f83068fa3767c5310052' }
      file_sha256 { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
      size { 1149.bytes }
    end

    trait(:object_storage) do
      file_store { Packages::PackageFileUploader::Store::REMOTE }
    end

    trait(:checksummed) do
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      verification_failure { 'Could not calculate the checksum' }
    end

    factory :package_file_with_file, traits: [:jar]
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
    association :package, package_type: :pypi
    required_python { '>=2.7' }
  end

  factory :nuget_metadatum, class: 'Packages::Nuget::Metadatum' do
    package { create(:nuget_package) }

    license_url { 'http://www.gitlab.com' }
    project_url { 'http://www.gitlab.com' }
    icon_url { 'http://www.gitlab.com' }
  end

  factory :conan_file_metadatum, class: 'Packages::Conan::FileMetadatum' do
    package_file { create(:conan_package_file, :conan_recipe_file, without_loaded_metadatum: true) }
    recipe_revision { '0' }
    conan_file_type { 'recipe_file' }

    trait(:recipe_file) do
      conan_file_type { 'recipe_file' }
    end

    trait(:package_file) do
      package_file { create(:conan_package_file, :conan_package, without_loaded_metadatum: true) }
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
    package { create(:nuget_package) }
    dependency { create(:packages_dependency) }
    dependency_type { :dependencies }

    trait(:with_nuget_metadatum) do
      after :build do |link|
        link.nuget_metadatum = build(:nuget_dependency_link_metadatum)
      end
    end
  end

  factory :nuget_dependency_link_metadatum, class: 'Packages::Nuget::DependencyLinkMetadatum' do
    dependency_link { create(:packages_dependency_link) }
    target_framework { '.NETStandard2.0' }
  end

  factory :packages_tag, class: 'Packages::Tag' do
    package
    sequence(:name) { |n| "tag-#{n}"}
  end
end
