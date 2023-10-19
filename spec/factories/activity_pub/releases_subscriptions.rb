# frozen_string_literal: true

FactoryBot.define do
  factory :activity_pub_releases_subscription, class: 'ActivityPub::ReleasesSubscription' do
    project
    subscriber_url { 'https://example.com/actor' }
    status { :requested }
    payload do
      {
        '@context': 'https://www.w3.org/ns/activitystreams',
        id: 'https://example.com/actor#follow/1',
        type: 'Follow',
        actor: 'https://example.com/actor',
        object: 'http://localhost/user/project/-/releases'
      }
    end

    trait :inbox do
      subscriber_inbox_url { 'https://example.com/actor/inbox' }
    end

    trait :shared_inbox do
      shared_inbox_url { 'https://example.com/shared-inbox' }
    end
  end
end
