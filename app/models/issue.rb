class Issue < ActiveRecord::Base
  include IssueCommonality
  include Votes

  attr_accessible :title, :assignee_id, :closed, :position, :description,
                  :milestone_id, :label_list, :author_id_of_changes

  acts_as_taggable_on :labels

  belongs_to :milestone

  validates :description, length: { within: 0..2000 }

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
#  id           :integer         not null, primary key
#  title        :string(255)
#  assignee_id  :integer
#  author_id    :integer
#  project_id   :integer
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  closed       :boolean         default(FALSE), not null
#  position     :integer         default(0)
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer
#
