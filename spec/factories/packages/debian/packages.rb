# frozen_string_literal: true

FactoryBot.define do
  factory :debian_package, class: 'Packages::Debian::Package' do
    project
    creator { project&.creator }
    status { :default }
    sequence(:name) { |n| "#{FFaker::Lorem.word}#{n}" }
    sequence(:version) { |n| "1.0-#{n}" }
    package_type { :debian }

    trait :pending_destruction do
      status { :pending_destruction }
    end

    transient do
      without_package_files { false }
      with_changes_file { false }
      file_metadatum_trait { processing? ? :unknown : :keep }
      published_in { :create }
    end

    publication do
      if published_in == :create
        association(:debian_publication, package: instance)
      elsif published_in
        association(:debian_publication, package: instance, distribution: published_in)
      end
    end

    package_files do
      package_files = []

      unless without_package_files
        package_files.push(
          association(:debian_package_file, :source, file_metadatum_trait, package: instance),
          association(:debian_package_file, :dsc, file_metadatum_trait, package: instance),
          association(:debian_package_file, :deb, file_metadatum_trait, package: instance),
          association(:debian_package_file, :deb_dev, file_metadatum_trait, package: instance),
          association(:debian_package_file, :udeb, file_metadatum_trait, package: instance),
          association(:debian_package_file, :ddeb, file_metadatum_trait, package: instance),
          association(:debian_package_file, :buildinfo, file_metadatum_trait, package: instance)
        )
      end

      if with_changes_file
        package_files.push(association(:debian_package_file, :changes, file_metadatum_trait, package: instance))
      end

      package_files
    end

    factory :debian_incoming do
      name { 'incoming' }
      version { nil }

      transient do
        without_package_files { false }
        file_metadatum_trait { :unknown }
        published_in { nil }
      end
    end

    factory :debian_temporary_with_files do
      status { :processing }

      transient do
        without_package_files { false }
        with_changes_file { false }
        file_metadatum_trait { :unknown }
        published_in { nil }
      end
    end

    factory :debian_temporary_with_changes do
      status { :processing }

      transient do
        without_package_files { true }
        with_changes_file { true }
        file_metadatum_trait { :unknown }
        published_in { nil }
      end
    end
  end
end
