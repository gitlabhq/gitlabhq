FactoryGirl.define do
  factory :project_snippet do
    project
    author
    title
    content
    file_name
  end
end
