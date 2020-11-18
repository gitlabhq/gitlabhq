# frozen_string_literal: true

FactoryBot.define do
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
      package { association(:conan_package, without_package_files: true) }

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

    trait(:generic) do
      package
      file_fixture { 'spec/fixtures/packages/generic/myfile.tar.gz' }
      file_name { "#{package.name}.tar.gz" }
      file_sha256 { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
      size { 1149.bytes }
    end

    trait(:object_storage) do
      file_store { Packages::PackageFileUploader::Store::REMOTE }
    end

    factory :package_file_with_file, traits: [:jar]
  end
end
