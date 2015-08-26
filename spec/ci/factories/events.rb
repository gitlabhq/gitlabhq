# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  project_id  :integer
#  user_id     :integer
#  is_admin    :integer
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

FactoryGirl.define do
  factory :event, class: Event do
    sequence :description do |n|
      "updated project settings#{n}"
    end

    factory :admin_event do
      is_admin true
    end
  end
end
