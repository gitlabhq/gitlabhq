# == Schema Information
#
# Table name: ci_events
#
#  id          :integer          not null, primary key
#  project_id  :integer
#  user_id     :integer
#  is_admin    :integer
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

module Ci
  class Event < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :project, class_name: 'Ci::Project'

    validates :description,
      presence: true,
      length: { in: 5..200 }

    scope :admin, ->(){ where(is_admin: true) }
    scope :project_wide, ->(){ where(is_admin: false) }
  end
end
