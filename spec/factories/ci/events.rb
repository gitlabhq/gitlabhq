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
  factory :ci_event, class: Ci::Event do
    sequence :description do |n|
      "updated project settings#{n}"
    end

    factory :ci_admin_event do
      is_admin true
    end
  end
end
