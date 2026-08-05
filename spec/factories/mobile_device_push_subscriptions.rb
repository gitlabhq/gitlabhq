# frozen_string_literal: true

FactoryBot.define do
  factory :mobile_device_push_subscription, class: 'Notifications::MobileDevicePushSubscription' do
    user
    sequence(:device_token) { |n| Digest::SHA256.hexdigest("device-token-#{n}") }
    platform { :ios }
    apns_environment { :production }
    payload_mode { :full }

    trait :with_device_details do
      bundle_identifier { 'com.gitlab-mobile.app' }
      device_name { 'iPhone 17 Pro' }
      app_version { '1.0.0' }
      locale { 'en' }
    end

    trait :sandbox do
      apns_environment { :sandbox }
    end
  end
end
