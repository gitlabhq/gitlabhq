# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :label do
    title "Bug"
    color "#990000"
    project
  end
end
