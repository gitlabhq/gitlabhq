# frozen_string_literal: true

FactoryBot.define do
  factory :composer_package, class: 'Packages::Composer::Package', parent: :package do
    sequence(:name) { |n| "composer-package-#{n}" }
    sequence(:version) { |n| "1.0.#{n}" }
    package_type { :composer }

    transient do
      sha { project.repository.find_branch('master').target }
      json { { name: name, version: version } }
    end

    trait(:with_metadatum) do
      composer_metadatum do
        association(:composer_metadatum, package: instance, target_sha: sha, composer_json: json)
      end
    end
  end
end
