# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :approver do
    target factory: :merge_request
    user
  end
end
