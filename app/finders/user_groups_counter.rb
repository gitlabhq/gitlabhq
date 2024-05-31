# frozen_string_literal: true

class UserGroupsCounter
  def initialize(user_ids)
    @user_ids = user_ids
  end

  def execute
    Namespace.unscoped do
      Namespace.from_union([
        groups,
        project_groups
      ]).group(:user_id).count # rubocop: disable CodeReuse/ActiveRecord
    end
  end

  private

  attr_reader :user_ids

  def groups
    Group.for_authorized_group_members(user_ids)
      .select('namespaces.*, members.user_id as user_id')
  end

  def project_groups
    Group.for_authorized_project_members(user_ids)
      .select('namespaces.*, project_authorizations.user_id as user_id')
  end
end
