FactoryBot.define do
  factory :release do
    tag "v1.1.0"
    name { tag }
    description "Awesome release"
    project
    author
  end
end
