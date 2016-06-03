# == Schema Information
#
# Table name: releases
#
#  id          :integer          not null, primary key
#  tag         :string
#  description :text
#  project_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class Release < ActiveRecord::Base
  belongs_to :project

  validates :description, :project, :tag, presence: true
end
