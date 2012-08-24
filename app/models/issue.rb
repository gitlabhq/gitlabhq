class Issue < ActiveRecord::Base
  include IssueCommonality
  include Upvote

  acts_as_taggable_on :labels

  belongs_to :milestone

  validates :description,
            length: { within: 0..2000 }

  def self.open_for(user)
    opened.assigned(user)
  end

  def is_assigned?
    !!assignee_id
  end

  def is_being_reassigned?
    assignee_id_changed?
  end

  def is_being_closed?
    closed_changed? && closed
  end

  def is_being_reopened?
    closed_changed? && !closed
  end
end
# == Schema Information
#
# Table name: issues
#
#  id           :integer(4)      not null, primary key
#  title        :string(255)
#  assignee_id  :integer(4)
#  author_id    :integer(4)
#  project_id   :integer(4)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  closed       :boolean(1)      default(FALSE), not null
#  position     :integer(4)      default(0)
#  critical     :boolean(1)      default(FALSE), not null
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer(4)
#

