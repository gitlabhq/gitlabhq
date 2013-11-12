# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :broadcast_message do
    message "MyText"
    starts_at "2013-11-12 13:43:25"
    ends_at "2013-11-12 13:43:25"
    alert_type 1
  end
end
