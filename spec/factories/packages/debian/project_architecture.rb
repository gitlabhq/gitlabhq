# frozen_string_literal: true

FactoryBot.define do
  factory :debian_project_architecture, class: 'Packages::Debian::ProjectArchitecture' do
    distribution { association(:debian_project_distribution) }

    sequence(:name) { |n| "project-arch-#{n}" }
  end
end
