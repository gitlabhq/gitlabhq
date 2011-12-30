require 'unique_public_key_validator'

class DeployKey < ActiveRecord::Base
  belongs_to :project

  validates :title,
            :presence => true,
            :length   => { :within => 0..255 }

  validates :key,
            :presence => true,
            :uniqueness => true,
            :length   => { :within => 0..5000 }

  validates_with UniquePublicKeyValidator

  before_save :set_identifier
  after_save :update_repository
  after_destroy :repository_delete_key

  def set_identifier
    self.identifier = "deploy_#{project.code}_#{Time.now.to_i}"
  end

  def update_repository
    Gitlabhq::GitHost.system.new.configure do |c|
      c.update_keys(identifier, key)
      c.update_project(project.path, project)
    end
  end

  def repository_delete_key
    Gitlabhq::GitHost.system.new.configure do |c|
      c.delete_key(identifier)
      c.update_project(project.path, project)
    end
  end

end
# == Schema Information
#
# Table name: keys
#
#  id         :integer         not null, primary key
#  project_id    :integer         not null
#  created_at :datetime
#  updated_at :datetime
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#


