# frozen_string_literal: true

FactoryBot.define do
  factory :helm_file_metadatum, class: 'Packages::Helm::FileMetadatum' do
    transient do
      description { nil }
    end

    project
    package_file { association(:helm_package_file, without_loaded_metadatum: true) }
    sequence(:channel) { |n| "#{FFaker::Lorem.word}-#{n}" }
    metadata do
      {
        name: package_file.package.name,
        version: package_file.package.version,
        apiVersion: 'v2'
      }.tap do |defaults|
        defaults['description'] = description if description
      end
    end
  end
end
