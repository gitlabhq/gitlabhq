# frozen_string_literal: true

FactoryBot.define do
  factory :rubygems_spec_file, class: 'Packages::Rubygems::SpecFile' do
    project
    size { 50.bytes }
    status { :default }
    file_name { 'specs.4.8.gz' }

    transient do
      file_fixture { 'spec/fixtures/packages/rubygems/specs.4.8.gz' }
    end

    after(:build) do |entry, evaluator|
      entry.file = fixture_file_upload(evaluator.file_fixture)
    end

    trait(:object_storage) do
      file_store { Packages::Rubygems::SpecFileUploader::Store::REMOTE }
    end
  end
end
