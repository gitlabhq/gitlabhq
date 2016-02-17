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

    trait :assigned do
      action { Task::ASSIGNED }
    end

    trait :mentioned do
      action { Task::MENTIONED }
    end
  end
end
