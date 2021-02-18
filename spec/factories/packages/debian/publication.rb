# frozen_string_literal: true

FactoryBot.define do
  factory :debian_publication, class: 'Packages::Debian::Publication' do
    package { association(:debian_package, published_in: nil) }

    distribution { association(:debian_project_distribution, project: package.project) }
  end
end
