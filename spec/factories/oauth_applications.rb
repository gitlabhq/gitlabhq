# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application, class: 'Authn::OauthApplication', aliases: [:application] do
    sequence(:name) { |n| "OAuth App #{n}" }
    uid { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    redirect_uri { generate(:url) }
    owner
    owner_type { 'User' }
  end

  trait :group_owned do
    owner_type { 'Group' }
    owner { association(:group) }
  end

  trait :dynamic do
    owner { nil }
    owner_type { nil }
    dynamic { true }
  end

  trait :without_owner do
    owner { nil }
    owner_type { nil }
    dynamic { false }
  end
end
