# frozen_string_literal: true

FactoryBot.define do
  factory :pypi_file_metadatum, class: 'Packages::Pypi::FileMetadatum' do
    package_file { association(:package_file, :pypi) }
    project { package_file.project }
    required_python { '==3.6.*' }
  end
end
