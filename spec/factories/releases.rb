FactoryGirl.define do
  factory :release do
    tag "v1.1.0"
    description "Awesome release"
    project factory: :empty_project
  end
end
