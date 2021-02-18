# frozen_string_literal: true

FactoryBot.define do
  factory :rubygems_metadatum, class: 'Packages::Rubygems::Metadatum' do
    package { association(:rubygems_package) }
    authors { FFaker::Name.name }
    email { FFaker::Internet.email }
  end
end
