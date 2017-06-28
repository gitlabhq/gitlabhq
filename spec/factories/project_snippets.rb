FactoryGirl.define do
  factory :project_snippet, parent: :snippet, class: :ProjectSnippet do
    project factory: :empty_project
  end
end
