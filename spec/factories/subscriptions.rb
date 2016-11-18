FactoryGirl.define do
  factory :subscription do
    user
    project factory: :empty_project
    subscribable factory: :issue
  end
end
