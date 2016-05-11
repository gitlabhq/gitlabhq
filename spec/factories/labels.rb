FactoryGirl.define do
  factory :label do
    sequence(:title) { |n| "label#{n}" }
    color "#990000"
    project
  end
end
