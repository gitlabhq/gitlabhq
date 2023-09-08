# frozen_string_literal: true

FactoryBot.define do
  factory :nuget_symbol, class: 'Packages::Nuget::Symbol' do
    package { association(:nuget_package) }
    file { fixture_file_upload('spec/fixtures/packages/nuget/symbol/package.pdb') }
    file_path { 'lib/net7.0/package.pdb' }
    size { 100.bytes }
    sequence(:signature) { |n| "b91a152048fc4b3883bf3cf73fbc03f#{n}FFFFFFFF" }
  end
end
