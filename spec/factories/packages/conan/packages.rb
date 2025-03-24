# frozen_string_literal: true

FactoryBot.define do
  factory :conan_package, class: 'Packages::Conan::Package', parent: :package do
    package_type { :conan }
    sequence(:name) { |n| "package-#{n}" }
    version { '1.0.0' }

    conan_metadatum { association(:conan_metadatum, package: instance) }

    transient do
      without_package_files { false }
      without_recipe_revisions { false }
      without_package_references { false }
    end

    conan_recipe_revisions do
      next [] if without_recipe_revisions

      [association(:conan_recipe_revision, package: instance)]
    end

    conan_package_references do
      next [] if without_package_references

      [association(:conan_package_reference, package: instance, recipe_revision: instance.conan_recipe_revisions.first)]
    end

    after :build do |package|
      package.conan_metadatum.package_username = ::Packages::Conan::Metadatum.package_username_from(
        full_path: package.project.full_path
      )
    end

    after :create do |package, evaluator|
      unless evaluator.without_package_files
        recipe_files = %i[conan_recipe_file conan_recipe_manifest]
        package_file_traits = %i[conan_package_info conan_package_manifest conan_package]
        recipe_files.each do |file|
          create :conan_package_file, file, package: package,
            conan_recipe_revision: package.conan_recipe_revisions.first
        end

        unless evaluator.without_package_references
          package_file_traits.each do |file|
            create :conan_package_file, file, package: package,
              conan_package_reference: package.conan_package_references.first,
              conan_recipe_revision: package.conan_recipe_revisions.first
          end
        end
      end
    end

    trait(:without_loaded_metadatum) do
      conan_metadatum { association(:conan_metadatum, package: nil, strategy: :build) }
    end
  end
end
