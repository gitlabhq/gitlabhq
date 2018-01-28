FactoryBot.define do
  factory :project_wiki do
    skip_create

    project
    user factory: :user
    initialize_with { new(project, user) }
  end
end
