# == Schema Information
#
# Table name: trigger_requests
#
#  id         :integer          not null, primary key
#  trigger_id :integer          not null
#  variables  :text
#  created_at :datetime
#  updated_at :datetime
#  commit_id  :integer
#

module Ci
  class TriggerRequest < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :trigger, class_name: 'Ci::Trigger'
    belongs_to :commit, class_name: 'Ci::Commit'
    has_many :builds, class_name: 'Ci::Build'

    serialize :variables
  end
end
