# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :approval do
    merge_request
    user
  end
end
