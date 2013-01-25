# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team do
    sequence(:name) { |n| "team#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    owner
  end
end
