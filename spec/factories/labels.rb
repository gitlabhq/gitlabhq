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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :label do
    sequence(:title) { |n| "bug-#{n}" }
    color "#990000"
    project
  end
end
