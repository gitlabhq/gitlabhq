FactoryGirl.define do
  factory :label do
    sequence(:title) { |n| "label#{n}" }
    color "#990000"
    subject factory: :project
  end

  factory :global_label, parent: :label do
    subject nil
    label_type Label.label_types[:global_label]
  end

  factory :group_label, parent: :label do
    label_type Label.label_types[:group_label]
  end

  factory :project_label, parent: :label do
    label_type Label.label_types[:project_label]
  end
end
