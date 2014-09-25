# == Schema Information
#
# Table name: forked_project_links
#
#  id                     :integer          not null, primary key
#  forked_to_project_id   :integer          not null
#  forked_from_project_id :integer          not null
#  created_at             :datetime
#  updated_at             :datetime
#

class ForkedProjectLink < ActiveRecord::Base
  belongs_to :forked_to_project, class_name: Project
  belongs_to :forked_from_project, class_name: Project
end
