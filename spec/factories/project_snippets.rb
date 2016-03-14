FactoryGirl.define do
  factory :project_snippet, parent: :snippet, class: :ProjectSnippet do
    project
  end
end
