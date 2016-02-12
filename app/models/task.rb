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

class Task < ActiveRecord::Base
  belongs_to :author, class_name: "User"
  belongs_to :project
  belongs_to :target, polymorphic: true, touch: true
  belongs_to :user

  validates :action, :project, :target, :user, presence: true

  state_machine :state, initial: :pending do
    state :pending
    state :done
  end
end
