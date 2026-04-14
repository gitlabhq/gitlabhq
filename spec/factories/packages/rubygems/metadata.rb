# frozen_string_literal: true

FactoryBot.define do
  factory :rubygems_metadatum, class: 'Packages::Rubygems::Metadatum' do
    package { association(:rubygems_package) }
    authors { FFaker::Name.name }
    email { FFaker::Internet.email }
    summary { FFaker::Lorem.sentence }
    description { FFaker::Lorem.paragraph }
    homepage { FFaker::Internet.http_url }
    platform { 'ruby' }
    require_paths { '["lib"]' }
    bindir { 'bin' }
    required_ruby_version { '>= 0' }
    required_rubygems_version { '>= 0' }
  end
end
