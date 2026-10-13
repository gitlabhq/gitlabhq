# frozen_string_literal: true

FactoryBot.define do
  factory :packages_dependency_link, class: 'Packages::DependencyLink' do
    package { association(:nuget_package) }
    dependency { association(:packages_dependency, project: package.project) }
    dependency_type { :dependencies }

    trait :with_nuget_metadatum do
      nuget_metadatum do
        association(:nuget_dependency_link_metadatum, strategy: :build, dependency_link: instance)
      end
    end

    trait :rubygems do
      package { association(:rubygems_package) }
      dependency { association(:packages_dependency, :rubygems) }
    end

    trait :dependencies do
      dependency_type { :dependencies }
    end

    trait :dev_dependencies do
      dependency_type { :devDependencies }
    end

    trait :bundle_dependencies do
      dependency_type { :bundleDependencies }
    end

    trait :peer_dependencies do
      dependency_type { :peerDependencies }
    end
  end
end
