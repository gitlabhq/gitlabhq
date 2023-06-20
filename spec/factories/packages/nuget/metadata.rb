# frozen_string_literal: true

FactoryBot.define do
  factory :nuget_metadatum, class: 'Packages::Nuget::Metadatum' do
    package { association(:nuget_package) }

    authors { 'Authors' }
    description { 'Description' }
    license_url { 'http://www.gitlab.com' }
    project_url { 'http://www.gitlab.com' }
    icon_url { 'http://www.gitlab.com' }
  end
end
