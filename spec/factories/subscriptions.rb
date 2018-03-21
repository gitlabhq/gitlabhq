FactoryBot.define do
  factory :subscription do
    project
    user { project.creator }
    subscribable factory: :issue
  end
end
