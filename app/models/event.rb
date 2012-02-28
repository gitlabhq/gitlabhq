class Event < ActiveRecord::Base
  Created   = 1
  Updated   = 2
  Closed    = 3
  Reopened  = 4
  Pushed    = 5
  Commented = 6

  belongs_to :project
  belongs_to :target, :polymorphic => true

  serialize :data

  def self.determine_action(record)
    if [Issue, MergeRequest].include? record.class
      Event::Created
    elsif record.kind_of? Note
      Event::Commented
    end
  end
end
# == Schema Information
#
# Table name: events
#
#  id          :integer         not null, primary key
#  target_type :string(255)
#  target_id   :integer
#  title       :string(255)
#  data        :text
#  project_id  :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  action      :integer
#

