# frozen_string_literal: true

class GroupDeployToken < ApplicationRecord
  belongs_to :group, class_name: '::Group'
  belongs_to :deploy_token, inverse_of: :group_deploy_tokens

  validates :deploy_token, presence: true
  validates :group, presence: true
  validates :deploy_token_id, uniqueness: { scope: [:group_id] }

  def has_access_to?(requested_project)
    requested_project_group = requested_project&.group
    return false unless requested_project_group
    return true if requested_project_group.id == group_id

    requested_project_group
      .ancestors
      .where(id: group_id)
      .exists?
  end
end
