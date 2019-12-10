# frozen_string_literal: true

class UserMention < ApplicationRecord
  self.abstract_class = true

  def has_mentions?
    mentioned_users_ids.present? || mentioned_groups_ids.present? || mentioned_projects_ids.present?
  end

  private

  def mentioned_users
    User.where(id: mentioned_users_ids)
  end

  def mentioned_groups
    Group.where(id: mentioned_groups_ids)
  end

  def mentioned_projects
    Project.where(id: mentioned_projects_ids)
  end
end
