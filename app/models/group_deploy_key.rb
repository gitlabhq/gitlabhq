# frozen_string_literal: true

class GroupDeployKey < Key
  self.table_name = 'group_deploy_keys'

  validates :user, presence: true

  def type
    'DeployKey'
  end
end
