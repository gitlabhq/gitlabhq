# frozen_string_literal: true

FactoryBot.define do
  factory :debian_project_component_file, class: 'Packages::Debian::ProjectComponentFile' do
    transient do
      file_fixture { 'spec/fixtures/packages/debian/distribution/Packages' }
    end

    component { association(:debian_project_component) }
    architecture { association(:debian_project_architecture, distribution: component.distribution) }

    factory :debian_group_component_file, class: 'Packages::Debian::GroupComponentFile' do
      component { association(:debian_group_component) }
      architecture { association(:debian_group_architecture, distribution: component.distribution) }
    end

    file_type { :packages }

    after(:build) do |component_file, evaluator|
      component_file.file = fixture_file_upload(evaluator.file_fixture) if evaluator.file_fixture.present?
    end

    file_sha256 { 'be93151dc23ac34a82752444556fe79b32c7a1ad' }

    trait(:packages) do
      file_type { :packages }
    end

    trait(:sources) do
      file_type { :sources }
      architecture { nil }
      file_fixture { 'spec/fixtures/packages/debian/distribution/Sources' }
    end

    trait(:di_packages) do
      file_type { :di_packages }
      file_fixture { 'spec/fixtures/packages/debian/distribution/D-I-Packages' }
    end

    trait(:older_sha256) do
      created_at { '2020-01-24T08:00:00Z' }
      file_sha256 { '157a1ad2b9102038560eea56771913b312ebf25093f5ef3b9842021c639c880d' }
      file_fixture { 'spec/fixtures/packages/debian/distribution/OtherSHA256' }
    end

    trait(:object_storage) do
      file_store { Packages::PackageFileUploader::Store::REMOTE }
    end

    trait(:empty) do
      file_sha256 { 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' }
      file_fixture { nil }
      size { 0 }
    end
  end
end
