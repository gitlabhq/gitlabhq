# frozen_string_literal: true

FactoryBot.define do
  factory :debian_project_component, class: 'Packages::Debian::ProjectComponent' do
    distribution { association(:debian_project_distribution) }

    sequence(:name) { |n| "#{FFaker::Lorem.word}#{n}" }
  end
end
