# frozen_string_literal: true

FactoryBot.define do
  factory :pypi_package, class: 'Packages::Pypi::Package', parent: :package do
    sequence(:name) { |n| "pypi-package-#{n}" }
    sequence(:version) { |n| "1.0.#{n}" }
    package_type { :pypi }

    transient do
      without_loaded_metadatum { false }
    end

    package_files do
      [association(:package_file, :pypi, package: instance, file_name: "#{instance.name}-#{instance.version}.tar.gz")]
    end

    pypi_metadatum do
      association(:pypi_metadatum, package: instance) unless without_loaded_metadatum
    end
  end
end
