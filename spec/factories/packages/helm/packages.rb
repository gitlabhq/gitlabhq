# frozen_string_literal: true

FactoryBot.define do
  factory :helm_package, class: 'Packages::Helm::Package', parent: :package do
    sequence(:name) { |n| "package-#{n}" }
    sequence(:version) { |n| "v1.0.#{n}" }
    package_type { :helm }

    transient do
      without_package_files { false }
    end

    package_files do
      if without_package_files
        []
      else
        [association(:helm_package_file, package: instance)]
      end
    end
  end
end
