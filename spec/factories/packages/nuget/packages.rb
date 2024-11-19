# frozen_string_literal: true

FactoryBot.define do
  factory :nuget_package, class: 'Packages::Nuget::Package', parent: :package do
    sequence(:name) { |n| "NugetPackage#{n}" }
    sequence(:version) { |n| "1.0.#{n}" }
    package_type { :nuget }

    transient do
      without_package_files { false }
    end

    package_files do
      if without_package_files
        []
      else
        [association(:package_file, :nuget, package: instance, file_name: "#{instance.name}.#{instance.version}.nupkg")]
      end
    end

    trait(:with_metadatum) do
      nuget_metadatum do
        association(:nuget_metadatum, package: instance)
      end
    end

    trait(:with_symbol_package) do
      package_files do
        package_files = []

        unless without_package_files
          package_files.push(
            association(
              :package_file,
              :nuget,
              package: instance,
              file_name: "#{instance.name}.#{instance.version}.nupkg"
            )
          )
        end

        package_files.push(
          association(
            :package_file,
            :snupkg,
            package: instance,
            file_name: "#{instance.name}.#{instance.version}.snupkg"
          )
        )

        package_files
      end
    end

    trait :with_build do
      build_infos do
        [association(:package_build_info, package: instance)]
      end
    end
  end
end
