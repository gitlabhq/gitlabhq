FactoryBot.define do
  factory :subscription do
    user
    project
    subscribable factory: :issue
  end
end
