FactoryBot.define do
  factory :user_list, parent: :list do
    list_type :assignee
    label nil
    user
  end
end
