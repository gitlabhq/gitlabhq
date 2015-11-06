# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :release do
    tag "v1.1.0"
    description "Awesome release"
    project
  end
end
