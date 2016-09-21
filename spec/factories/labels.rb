FactoryGirl.define do
  factory :label, class: ProjectLabel do
    sequence(:title) { |n| "label#{n}" }
    color "#990000"
    project
  end

  factory :group_label, class: GroupLabel do
    sequence(:title) { |n| "label#{n}" }
    color "#990000"
    group
  end
end
