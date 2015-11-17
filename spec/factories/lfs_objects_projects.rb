# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :lfs_objects_project do
    lfs_object
    project
  end
end
