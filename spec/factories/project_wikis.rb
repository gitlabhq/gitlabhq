FactoryGirl.define do
  factory :project_wiki do
    project factory: :empty_project
    user factory: :user
    initialize_with { new(project, user) }
  end
end
