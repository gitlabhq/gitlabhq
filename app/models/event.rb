class Event < ActiveRecord::Base
  belongs_to :project
  serialize :data
end
# == Schema Information
#
# Table name: events
#
#  id         :integer         not null, primary key
#  data_type  :string(255)
#  data_id    :string(255)
#  title      :string(255)
#  data       :text
#  project_id :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#
