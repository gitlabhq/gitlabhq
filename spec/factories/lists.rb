FactoryGirl.define do
  factory :list do
    board
    label
    sequence(:position)
  end
end
