# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :approve do
    merge_request
    user
  end
end
