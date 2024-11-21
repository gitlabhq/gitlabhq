# frozen_string_literal: true

FactoryBot.define do
  factory :rubygems_package, class: 'Packages::Rubygems::Package' do
    project
    creator { project&.creator }
    status { :default }

    sequence(:name) { |n| "my_gem_#{n}" }
    sequence(:version) { |n| "1.#{n}" }
    package_type { :rubygems }

    package_files do
      next [] if without_package_files

      [association(:package_file, processing? ? :unprocessed_gem : :gem, package: instance)].tap do |arr|
        arr.push(association(:package_file, :gemspec, package: instance)) unless processing?
      end
    end

    transient do
      without_package_files { false }
    end

    trait(:with_metadatum) do
      rubygems_metadatum do
        association(:rubygems_metadatum, package: instance)
      end
    end
  end
end
