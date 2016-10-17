# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :approver_group do
    target factory: :merge_request
    group
  end
end
