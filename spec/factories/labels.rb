# == Schema Information
#
# Table name: labels
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  color      :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  template   :boolean          default(FALSE)
#

FactoryGirl.define do
  factory :label do
    sequence(:title) { |n| "label#{n}" }
    color "#990000"
    project
  end
end
