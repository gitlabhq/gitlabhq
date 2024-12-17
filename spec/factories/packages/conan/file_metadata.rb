# frozen_string_literal: true

FactoryBot.define do
  factory :conan_file_metadatum, class: 'Packages::Conan::FileMetadatum' do
    package_file { association(:conan_package_file, :conan_recipe_file, without_loaded_metadatum: true) }
    conan_file_type { 'recipe_file' }

    trait(:recipe_file) do
      conan_file_type { 'recipe_file' }
    end

    trait(:package_file) do
      package_file { association(:conan_package_file, :conan_package, without_loaded_metadatum: true) }
      conan_file_type { 'package_file' }
      package_reference { association(:conan_package_reference) }
      conan_package_reference { package_reference.reference }
    end
  end
end
