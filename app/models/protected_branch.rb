# == Schema Information
#
# Table name: protected_branches
#
#  id                  :integer          not null, primary key
#  project_id          :integer          not null
#  name                :string(255)      not null
#  created_at          :datetime
#  updated_at          :datetime
#  developers_can_push :boolean          default(FALSE), not null
#

class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  def commit
    project.commit(self.name)
  end
end
