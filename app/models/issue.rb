# == Schema Information
#
# Table name: issues
#
#  id           :integer          not null, primary key
#  title        :string(255)
#  assignee_id  :integer
#  author_id    :integer
#  project_id   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  position     :integer          default(0)
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer
#  state        :string(255)
#

class Issue < ActiveRecord::Base
  include Issuable

  attr_accessible :title, :assignee_id, :position, :description,
                  :milestone_id, :label_list, :author_id_of_changes,
                  :state_event

  acts_as_taggable_on :labels

  scope :cared, ->(user) { where(assignee_id: user) }
  scope :authored, ->(user) { where(author_id: user) }
  scope :open_for, ->(user) { opened.assigned_to(user) }

  state_machine :state, initial: :opened do
    event :close do
      transition [:reopened, :opened] => :closed
    end

    event :reopen do
      transition closed: :reopened
    end

    state :opened

    state :reopened

    state :closed
  end

  # Both open and reopened issues should be listed as opened
  scope :opened, -> { with_state(:opened, :reopened) }
end
