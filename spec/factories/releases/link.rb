# frozen_string_literal: true

FactoryBot.define do
  factory :release_link, class: '::Releases::Link' do
    release
    sequence(:name) { |n| "release-18.#{n}.dmg" }
    sequence(:url) { |n| "https://example.com/scrambled-url/app-#{n}.zip" }
    sequence(:filepath) { |n| "/binaries/awesome-app-#{n}" }
    link_type { 'other' }
  end
end
