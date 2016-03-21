# == Schema Information
#
# Table name: broadcast_messages
#
#  id         :integer          not null, primary key
#  message    :text             not null
#  starts_at  :datetime
#  ends_at    :datetime
#  created_at :datetime
#  updated_at :datetime
#  color      :string(255)
#  font       :string(255)
#

FactoryGirl.define do
  factory :broadcast_message do
    message "MyText"
    starts_at Date.today
    ends_at Date.tomorrow

    trait :expired do
      starts_at 5.days.ago
      ends_at 3.days.ago
    end

    trait :future do
      starts_at 5.days.from_now
      ends_at 6.days.from_now
    end
  end
end
