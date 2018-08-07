FactoryBot.define do
  factory :user_list, parent: :list do
    list_type :assignee
    label nil
    user
  end

  factory :milestone_list, parent: :list do
    list_type :milestone
    label nil
    user nil
    milestone
  end
end
