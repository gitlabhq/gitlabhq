# frozen_string_literal: true

FactoryBot.define do
  factory :debian_project_architecture, class: 'Packages::Debian::ProjectArchitecture' do
    distribution { association(:debian_project_distribution) }

    sequence(:name) { |n| "#{FFaker::Lorem.word}#{n}" }
  end
end
