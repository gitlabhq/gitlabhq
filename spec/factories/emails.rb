FactoryGirl.define do
  factory :email do
    user
    email { FFaker::Internet.email('alias') }
  end
end
