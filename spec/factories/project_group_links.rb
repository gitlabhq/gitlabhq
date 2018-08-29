FactoryBot.define do
  factory :project_group_link do
    project
    group
    expires_at nil
  end
end
