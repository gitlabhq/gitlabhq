# frozen_string_literal: true

FactoryBot.define do
  factory :custom_emoji, class: 'CustomEmoji' do
    sequence(:name) { |n| "custom_emoji#{n}" }
    namespace
    file { fixture_file_upload(Rails.root.join('spec/fixtures/dk.png')) }
  end
end
