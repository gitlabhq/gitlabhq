# frozen_string_literal: true

FactoryBot.define do
  factory :conan_metadatum, class: 'Packages::Conan::Metadatum' do
    association :package, factory: [:conan_package, :without_loaded_metadatum], without_package_files: true
    package_username { 'username' }
    package_channel { 'stable' }
  end
end
