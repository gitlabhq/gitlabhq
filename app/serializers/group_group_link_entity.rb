# frozen_string_literal: true

class GroupGroupLinkEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :created_at
  expose :expires_at do |group_link|
    group_link.expires_at&.to_time
  end

  expose :can_update do |group_link|
    can_manage?(group_link)
  end

  expose :can_remove do |group_link|
    can_manage?(group_link)
  end

  expose :access_level do
    expose :human_access, as: :string_value
    expose :group_access, as: :integer_value
  end

  expose :valid_roles do |group_link|
    group_link.class.access_options
  end

  expose :shared_with_group do
    expose :avatar_url do |group_link|
      group_link.shared_with_group.avatar_url(only_path: false)
    end

    expose :web_url do |group_link|
      group_link.shared_with_group.web_url
    end

    expose :shared_with_group, merge: true, using: GroupBasicEntity
  end

  private

  def current_user
    options[:current_user]
  end

  def can_manage?(group_link)
    can?(current_user, :admin_group_member, group_link.shared_group)
  end
end
