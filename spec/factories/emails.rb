FactoryBot.define do
  factory :email do
    user
    email { generate(:email_alias) }

    trait(:confirmed) { confirmed_at Time.now }
  end
end
