# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application, class: 'Doorkeeper::Application', aliases: [:application] do
    sequence(:name) { |n| "OAuth App #{n}" }
    uid { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    redirect_uri { generate(:url) }
    owner
    owner_type { 'User' }
  end
end
