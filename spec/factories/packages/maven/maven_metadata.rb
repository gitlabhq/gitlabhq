# frozen_string_literal: true

FactoryBot.define do
  factory :maven_metadatum, class: 'Packages::Maven::Metadatum' do
    package { association(:maven_package, maven_metadatum: nil) }
    path { 'my/company/app/my-app/1.0-SNAPSHOT' }
    app_group { 'my.company.app' }
    app_name { 'my-app' }
    app_version { '1.0-SNAPSHOT' }
  end
end
