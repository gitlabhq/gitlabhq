# frozen_string_literal: true

FactoryBot.define do
  factory :nuget_dependency_link_metadatum, class: 'Packages::Nuget::DependencyLinkMetadatum' do
    dependency_link { association(:packages_dependency_link) }
    target_framework { '.NETStandard2.0' }
  end
end
