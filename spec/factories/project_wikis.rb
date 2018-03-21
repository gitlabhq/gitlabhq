FactoryBot.define do
  factory :project_wiki do
    skip_create

    project
    user { project.creator }
    initialize_with { new(project, user) }
  end
end
