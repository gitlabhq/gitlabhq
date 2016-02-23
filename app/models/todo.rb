# == Schema Information
#
# Table name: todos
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  project_id  :integer          not null
#  target_id   :integer          not null
#  target_type :string           not null
#  author_id   :integer
#  note_id     :integer
#  action      :integer          not null
#  state       :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#

class Todo < ActiveRecord::Base
  ASSIGNED  = 1
  MENTIONED = 2

  belongs_to :author, class_name: "User"
  belongs_to :note
  belongs_to :project
  belongs_to :target, polymorphic: true, touch: true
  belongs_to :user

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :action, :project, :target, :user, presence: true

  default_scope { reorder(id: :desc) }

  scope :pending, -> { with_state(:pending) }
  scope :done, -> { with_state(:done) }

  state_machine :state, initial: :pending do
    event :done do
      transition [:pending, :done] => :done
    end

    state :pending
    state :done
  end

  def body
    if note.present?
      note.note
    else
      target.title
    end
  end
end
