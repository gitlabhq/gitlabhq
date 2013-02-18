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
#  state        :string           default(FALSE), not null
#  position     :integer          default(0)
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer
#

class Issue < ActiveRecord::Base
  include Issuable

  attr_accessible :title, :assignee_id, :position, :description,
                  :milestone_id, :label_list, :author_id_of_changes,
                  :state_event

  acts_as_taggable_on :labels

  state_machine :state, :initial => :opened do
    event :close do
      transition [:reopened, :opened] => :closed
    end

    event :reopen do
      transition :closed => :reopened
    end

    state :opened

    state :reopened

    state :closed
  end


  def self.open_for(user)
    opened.assigned(user)
  end
end
