require_relative '../support/test_env'

FactoryGirl.define do
  factory :custom_emoji, class: 'CustomEmoji' do
    sequence(:name) { |n| "custom_emoji#{n}" }
    namespace
    file { File.open(Rails.root.join('spec/fixtures/dk.png')) }
  end
end
