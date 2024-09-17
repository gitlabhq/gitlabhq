# frozen_string_literal: true

FactoryBot.define do
  factory :generic_package, class: 'Packages::Generic::Package', parent: :package do
    sequence(:name) { |n| "generic-package-#{n}" }
    version { '1.0.0' }
    package_type { :generic }

    trait(:with_zip_file) do
      package_files do
        [association(:package_file, :generic_zip, package: instance)]
      end
    end
  end
end
