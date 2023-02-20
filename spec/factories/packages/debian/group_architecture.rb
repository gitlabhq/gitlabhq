# frozen_string_literal: true

FactoryBot.define do
  factory :debian_group_architecture, class: 'Packages::Debian::GroupArchitecture' do
    distribution { association(:debian_group_distribution) }

    sequence(:name) { |n| "#{FFaker::Lorem.word}#{n}" }
  end
end
