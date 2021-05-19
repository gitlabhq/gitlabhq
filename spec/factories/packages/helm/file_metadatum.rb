# frozen_string_literal: true

FactoryBot.define do
  factory :helm_file_metadatum, class: 'Packages::Helm::FileMetadatum' do
    package_file { association(:helm_package_file, without_loaded_metadatum: true) }
    channel { 'stable' }
    metadata { { 'name': package_file.package.name, 'version': package_file.package.version, 'apiVersion': 'v2' } }
  end
end
