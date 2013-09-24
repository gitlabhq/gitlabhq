# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer          not null, primary key
#  project_id :integer          not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter

  attr_accessible :name

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  def commit
    project.repository.commit(self.name)
  end
end
