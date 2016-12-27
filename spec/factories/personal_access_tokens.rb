FactoryGirl.define do
  factory :personal_access_token do
    user
    token { SecureRandom.hex(50) }
    name { FFaker::Product.brand }
    revoked false
    expires_at { 5.days.from_now }
    scopes ['api']

    factory :revoked_personal_access_token do
      revoked true
    end

    factory :expired_personal_access_token do
      expires_at { 1.day.ago }
    end
  end
end
