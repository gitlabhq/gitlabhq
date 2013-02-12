# == Schema Information
#
# Table name: user_teams
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  path       :string(255)
#  owner_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team do
    sequence(:name) { |n| "team#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    owner
  end
end
