# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :blocking_ip do
    ip "MyString"
    description "MyText"
    type ""
  end
end
