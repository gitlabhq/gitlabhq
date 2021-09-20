# frozen_string_literal: true

FactoryBot.define do
  factory :pypi_metadatum, class: 'Packages::Pypi::Metadatum' do
    package { association(:pypi_package, without_loaded_metadatum: true) }
    required_python { '>=2.7' }
  end
end
