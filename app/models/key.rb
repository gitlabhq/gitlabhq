class Key < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :title,
            :presence => true,
            :length   => { :within => 0..255 }

  validates :key,
            :presence => true,
            :uniqueness => true,
            :length   => { :within => 0..5000 }

  before_save :set_identifier
  after_save :update_repository
  after_destroy :repository_delete_key

  def set_identifier
    if is_deploy_key
      self.identifier = "deploy_#{project.code}_#{Time.now.to_i}"
    else
      self.identifier = "#{user.identifier}_#{Time.now.to_i}"
    end
  end

  def update_repository
    Gitlabhq::GitHost.system.new.configure do |c|
      c.update_keys(identifier, key)
      c.update_projects(projects)
    end
  end

  def repository_delete_key
    Gitlabhq::GitHost.system.new.configure do |c|
      c.delete_key(identifier)
      c.update_projects(projects)
    end
  end
  
  def is_deploy_key
    true if project_id
  end

   #projects that has this key
  def projects
    if is_deploy_key
      [project]
    else
      user.projects
    end
  end
end
# == Schema Information
#
# Table name: keys
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#  project_id :integer
#

