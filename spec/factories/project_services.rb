# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project_service do
    service_hook_name "MyString"
    project_id 1
    active false
    data "MyText"
  end
end
