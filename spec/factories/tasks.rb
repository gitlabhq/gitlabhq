# == Schema Information
#
# Table name: tasks
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  project_id  :integer          not null
#  target_id   :integer          not null
#  target_type :string           not null
#  author_id   :integer
#  action      :integer
#  state       :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#

FactoryGirl.define do
  factory :task do
    project
    author
    user

    factory :pending_assigned_task, traits: [:assgined, :pending]

    trait :assgined do
      action { Task::ASSIGNED }
    end

    trait :pending do
      state { :pending }
    end
  end
end
