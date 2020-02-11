# frozen_string_literal: true

## It's expected to delete one record on GitLab.com
#
class RemoveEmptyGithubServiceTemplates < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  class Service < ActiveRecord::Base
    self.table_name = 'services'
    self.inheritance_column = :_type_disabled

    serialize :properties, JSON
  end

  def up
    relationship.where(properties: {}).delete_all
  end

  def down
    relationship.find_or_create_by!(properties: {})
  end

  private

  def relationship
    RemoveEmptyGithubServiceTemplates::Service.where(template: true, type: 'GithubService')
  end
end
