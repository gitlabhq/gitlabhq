# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :approver do
    target factory: :merge_request
    user
  end
end
