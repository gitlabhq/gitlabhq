# == Schema Information
#
# Table name: runners
#
#  id           :integer          not null, primary key
#  token        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  description  :string(255)
#  contacted_at :datetime
#  active       :boolean          default(TRUE), not null
#  is_shared    :boolean          default(FALSE)
#  name         :string(255)
#  version      :string(255)
#  revision     :string(255)
#  platform     :string(255)
#  architecture :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ci_runner, class: Ci::Runner do
    sequence :description do |n|
      "My runner#{n}"
    end

    platform "darwin"

    factory :ci_shared_runner do
      is_shared true
    end

    factory :ci_specific_runner do
      is_shared false
    end
  end
end
