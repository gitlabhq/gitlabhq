# frozen_string_literal: true

FactoryBot.define do
  factory :conan_package, class: 'Packages::Conan::Package', parent: :package do
    package_type { :conan }
    sequence(:name) { |n| "package-#{n}" }
    version { '1.0.0' }

    conan_metadatum

    transient do
      without_package_files { false }
      package_references { ['1234567890abcdef1234567890abcdef12345678'] }
    end

    conan_package_references do
      package_references.map do |ref|
        association(:conan_package_reference,
          reference: ref, package: instance)
      end
    end

    after :build do |package|
      package.conan_metadatum.package_username = ::Packages::Conan::Metadatum.package_username_from(
        full_path: package.project.full_path
      )
    end

    after :create do |package, evaluator|
      unless evaluator.without_package_files
        %i[conan_recipe_file conan_recipe_manifest].each do |file|
          create :conan_package_file, file, package: package
        end

        package_file_traits = %i[conan_package_info conan_package_manifest conan_package]
        package.conan_package_references.each do |reference|
          package_file_traits.each do |file|
            create :conan_package_file, file, package: package,
              conan_package_reference: reference
          end
        end
      end
    end

    trait(:without_loaded_metadatum) do
      conan_metadatum { association(:conan_metadatum, package: nil, strategy: :build) }
    end
  end
end
