#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

class ProjectGroupLink < ActiveRecord::Base
  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MASTER    = 40

  belongs_to :project
  belongs_to :group

  validates :project_id, presence: true
  validates :group_id, presence: true
  validates :group_id, uniqueness: { scope: [:project_id], message: "already shared with this group" }

  def self.access_options
    {
      "Guest"     => GUEST,
      "Reporter"  => REPORTER,
      "Developer" => DEVELOPER,
      "Master"    => MASTER
    }
  end

  def self.default_access
    DEVELOPER
  end

  def human_access
    self.class.access_options.key(self.group_access)
  end
end
