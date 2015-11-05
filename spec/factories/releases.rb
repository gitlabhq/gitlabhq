# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :release do
    tag "MyString"
    description "MyText"
    project_id 1
  end
end
