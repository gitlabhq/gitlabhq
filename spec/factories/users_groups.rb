# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :users_group do
    access_level 1
    group_id 1
    user_id 1
  end
end
