# frozen_string_literal: true

FactoryBot.define do
  factory :maven_package, class: 'Packages::Maven::Package', parent: :package do
    name { 'my/company/app/my-app' }
    sequence(:version) { |n| "1.#{n}-SNAPSHOT" }
    package_type { :maven }

    maven_metadatum do
      association(
        :maven_metadatum,
        path: instance.version? ? "#{instance.name}/#{instance.version}" : instance.name,
        package: instance
      )
    end

    package_files do
      [
        association(:package_file, :xml, package: instance),
        association(:package_file, :jar, package: instance),
        association(:package_file, :pom, package: instance)
      ]
    end
  end
end
