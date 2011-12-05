class Key < ActiveRecord::Base
  belongs_to :user

  validates :title,
            :presence => true,
            :length   => { :within => 0..255 }

  validates :key,
            :presence => true,
            :uniqueness => true,
            :length   => { :within => 0..5000 }

  before_save :set_identifier
  after_save :update_gitosis
  after_destroy :gitosis_delete_key

  def set_identifier
    self.identifier = "#{user.identifier}_#{Time.now.to_i}"
  end

  def update_gitosis
    Gitlabhq::GitHost.system.new.configure do |c|
      c.update_keys(identifier, key)

      projects.each do |project|
        c.update_project(project.path, project.gitosis_writers)
      end
    end
  end

  def gitosis_delete_key
    Gitlabhq::GitHost.system.new.configure do |c|
      c.delete_key(identifier)

      projects.each do |project|
        c.update_project(project.path, project.gitosis_writers)
      end
    end
  end

   #projects that has this key
  def projects
    user.projects
  end
end
# == Schema Information
#
# Table name: keys
#
#  id         :integer         not null, primary key
#  user_id    :integer         not null
#  created_at :datetime
#  updated_at :datetime
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#

