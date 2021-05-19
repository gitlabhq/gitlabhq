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

    factory :debian_package_file do
      package { association(:debian_package, without_package_files: true) }
      file_name { 'libsample0_1.2.3~alpha2_amd64.deb' }
      file_fixture { "spec/fixtures/packages/debian/#{file_name}" }
      file_sha1 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }
      file_md5 { '12345abcde' }
      size { 400.kilobytes }

      transient do
        without_loaded_metadatum { false }
        file_metadatum_trait { :deb }
      end

      after :create do |package_file, evaluator|
        unless evaluator.without_loaded_metadatum
          create :debian_file_metadatum, evaluator.file_metadatum_trait, package_file: package_file
        end
      end

      trait(:unknown) do
        package { association(:debian_incoming, without_package_files: true) }

        transient do
          file_metadatum_trait { :unknown }
        end
      end

      trait(:invalid) do
        file_name { 'README.md' }
      end

      trait(:source) do
        file_name { 'sample_1.2.3~alpha2.tar.xz' }
        file_md5 { 'd79b34f58f61ff4ad696d9bd0b8daa68' }
        file_sha1 { '5f8bba5574eb01ac3b1f5e2988e8c29307788236' }
        file_sha256 { 'b5a599e88e7cbdda3bde808160a21ba1dd1ec76b2ec8d4912aae769648d68362' }

        transient do
          file_metadatum_trait { :source }
        end
      end

      trait(:dsc) do
        file_name { 'sample_1.2.3~alpha2.dsc' }
        file_md5 { '3b0817804f669e16cdefac583ad88f0e' }
        file_sha1 { '32ecbd674f0bfd310df68484d87752490685a8d6' }
        file_sha256 { '844f79825b7e8aaa191e514b58a81f9ac1e58e2180134b0c9512fa66d896d7ba' }

        transient do
          file_metadatum_trait { :dsc }
        end
      end

      trait(:deb) do
        file_name { 'libsample0_1.2.3~alpha2_amd64.deb' }
        file_md5 { 'fb0842b21adc44207996296fe14439dd' }
        file_sha1 { '5248b95600e85bfe7f63c0dfce330a75f5777366' }
        file_sha256 { '1c383a525bfcba619c7305ccd106d61db501a6bbaf0003bf8d0c429fbdb7fcc1' }

        transient do
          file_metadatum_trait { :deb }
        end
      end

      trait(:deb2) do
        file_name { 'sample-dev_1.2.3~binary_amd64.deb' }
        file_md5 { 'd2afbd28e4d74430d22f9504e18bfdf5' }
        file_sha1 { 'f81e4f66c8c6bb899653a3340c157965ee69634f' }
        file_sha256 { '9fbeee2191ce4dab5288fad5ecac1bd369f58fef9a992a880eadf0caf25f086d' }

        transient do
          file_metadatum_trait { :deb }
        end
      end

      trait(:udeb) do
        file_name { 'sample-udeb_1.2.3~alpha2_amd64.udeb' }
        file_md5 { '72b1dd7d98229e2fb0355feda1d3a165' }
        file_sha1 { 'e42e8f2fe04ed1bb73b44a187674480d0e49dcba' }
        file_sha256 { '2b0c152b3ab4cc07663350424de972c2b7621d69fe6df2e0b94308a191e4632f' }

        transient do
          file_metadatum_trait { :udeb }
        end
      end

      trait(:buildinfo) do
        file_name { 'sample_1.2.3~alpha2_amd64.buildinfo' }
        file_md5 { '4e085dd67c120ca967ec314f65770a42' }
        file_sha1 { '0d47e899f3cc67a2253a4629456ff927e0db5c60' }
        file_sha256 { 'f9900d3c94e94b329232668dcbef3dba2d96c07147b15b6dc0533452e4dd8a43' }

        transient do
          file_metadatum_trait { :buildinfo }
        end
      end

      trait(:changes) do
        file_name { 'sample_1.2.3~alpha2_amd64.changes' }

        transient do
          file_metadatum_trait { :changes }
        end
      end

      trait(:keep) do
      end
    end

    factory :helm_package_file do
      package { association(:helm_package, without_package_files: true) }
      file_name { "#{package.name}-#{package.version}.tgz" }
      file_fixture { "spec/fixtures/packages/helm/rook-ceph-v1.5.8.tgz" }

      transient do
        without_loaded_metadatum { false }
        channel { 'stable' }
      end

      after :create do |package_file, evaluator|
        unless evaluator.without_loaded_metadatum
          create :helm_file_metadatum, package_file: package_file, channel: evaluator.channel
        end
      end
    end

    trait(:jar) do
      file_fixture { 'spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.jar' }
      file_name { 'my-app-1.0-20180724.124855-1.jar' }
      file_sha1 { '4f0bfa298744d505383fbb57c554d4f5c12d88b3' }
      file_md5 { '0a7392d24f42f83068fa3767c5310052' }
      file_sha256 { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
      size { 100.kilobytes }
    end

    trait(:pom) do
      file_fixture { 'spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.pom' }
      file_name { 'my-app-1.0-20180724.124855-1.pom' }
      file_sha1 { '19c975abd49e5102ca6c74a619f21e0cf0351c57' }
      file_md5 { '0a7392d24f42f83068fa3767c5310052' }
      file_sha256 { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
      size { 200.kilobytes }
    end

    trait(:xml) do
      file_fixture { 'spec/fixtures/packages/maven/maven-metadata.xml' }
      file_name { 'maven-metadata.xml' }
      file_sha1 { '42b1bdc80de64953b6876f5a8c644f20204011b0' }
      file_md5 { '0a7392d24f42f83068fa3767c5310052' }
      file_sha256 { '440e5e148a25331bbd7991575f7d54933c0ebf6cc735a18ee5066ac1381bb590' }
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

    trait(:terraform_module) do
      file_fixture { 'spec/fixtures/packages/terraform_module/module-system-v1.0.0.tgz' }
      file_name { 'module-system-v1.0.0.tgz' }
      file_sha1 { 'abf850accb1947c0c0e3ef4b441b771bb5c9ae3c' }
      size { 806.bytes }
    end

    trait(:nuget) do
      package
      file_fixture { 'spec/fixtures/packages/nuget/package.nupkg' }
      file_name { 'package.nupkg' }
      file_sha1 { '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57' }
      size { 300.kilobytes }
    end

    trait(:gem) do
      package
      file_fixture { 'spec/fixtures/packages/rubygems/package-0.0.1.gem' }
      file_name { 'package-0.0.1.gem' }
      file_sha1 { '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57' }
      size { 4.kilobytes }
    end

    trait(:unprocessed_gem) do
      package
      file_fixture { 'spec/fixtures/packages/rubygems/package.gem' }
      file_name { 'package.gem' }
      file_sha1 { '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57' }
      size { 4.kilobytes }
    end

    trait(:gemspec) do
      package
      file_fixture { 'spec/fixtures/packages/rubygems/package.gemspec' }
      file_name { 'package.gemspec' }
      file_sha1 { '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57' }
      size { 242.bytes }
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
