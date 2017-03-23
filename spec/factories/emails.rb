FactoryGirl.define do
  factory :email do
    user
    email { generate(:email_alias) }
  end
end
