FactoryGirl.define do
  factory :doorkeeper_access_grant, class: Doorkeeper::AccessGrant do
    sequence(:resource_owner_id) { |n| n }
    association :application, factory: :doorkeeper_application
    redirect_uri 'https://app.com/callback'
    expires_in 100
    scopes 'public write'
  end

  factory :doorkeeper_access_token, class: Doorkeeper::AccessToken do
    sequence(:resource_owner_id) { |n| n }
    association :application, factory: :doorkeeper_application
    expires_in 2.hours

    factory :clientless_access_token do
      application nil
    end
  end

  factory :doorkeeper_application, class: Doorkeeper::Application do
    sequence(:name) { |n| "Application #{n}" }
    redirect_uri 'https://app.com/callback'
  end
end
