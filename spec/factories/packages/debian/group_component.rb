# frozen_string_literal: true

FactoryBot.define do
  factory :debian_group_component, class: 'Packages::Debian::GroupComponent' do
    distribution { association(:debian_group_distribution) }

    sequence(:name) { |n| "#{FFaker::Lorem.word}#{n}" }
  end
end
