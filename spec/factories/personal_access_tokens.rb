FactoryGirl.define do
  factory :personal_access_token do
    user
    token { SecureRandom.hex(50) }
    name { FFaker::Product.brand }
    revoked false
    expires_at { 5.days.from_now }
  end
end
