FactoryGirl.define do
  factory :label_priority do
    project factory: :empty_project
    label
    sequence(:priority)
  end
end
