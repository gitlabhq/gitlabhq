FactoryGirl.define do
  factory :board_filter do
    association :board
    association :milestone
    association :author, factory: :user
    association :assignee, factory: :user
  end
end
