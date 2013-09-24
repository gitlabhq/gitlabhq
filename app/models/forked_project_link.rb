# == Schema Information
#
# Table name: forked_project_links
#
#  id                     :integer          not null, primary key
#  forked_to_project_id   :integer          not null
#  forked_from_project_id :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class ForkedProjectLink < ActiveRecord::Base
  attr_accessible :forked_from_project_id, :forked_to_project_id

  # Relations
  belongs_to :forked_to_project, class_name: Project
  belongs_to :forked_from_project, class_name: Project

end
