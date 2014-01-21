# == Schema Information
#
# Table name: broadcast_messages
#
#  id         :integer          not null, primary key
#  message    :text             default(""), not null
#  starts_at  :datetime
#  ends_at    :datetime
#  alert_type :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color      :string(255)
#  font       :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :broadcast_message do
    message "MyText"
    starts_at "2013-11-12 13:43:25"
    ends_at "2013-11-12 13:43:25"
    alert_type 1
    color "#555555"
    font "#BBBBBB"
  end
end
