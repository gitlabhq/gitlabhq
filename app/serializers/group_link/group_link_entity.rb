# frozen_string_literal: true

module GroupLink
  class GroupLinkEntity < Grape::Entity
    include RequestAwareEntity

    expose :id
    expose :created_at
    expose :expires_at do |group_link|
      group_link.expires_at&.to_time
    end

    expose :access_level do
      expose :human_access, as: :string_value
      expose :group_access, as: :integer_value
    end

    expose :is_shared_with_group_private do |group_link|
      !can_read_shared_group?(group_link)
    end

    expose :shared_with_group do
      expose :avatar_url, if: ->(group_link) { can_read_shared_group?(group_link) } do |group_link|
        group_link.shared_with_group.avatar_url(only_path: false, size: Member::AVATAR_SIZE)
      end

      expose :web_url, if: ->(group_link) { can_read_shared_group?(group_link) } do |group_link|
        group_link.shared_with_group.web_url
      end

      # We have to expose shared_with_group.id because we use this to get distinct
      # with ancestors
      expose :shared_with_group, merge: true do |group_link|
        if can_read_shared_group?(group_link)
          GroupBasicEntity.represent(group_link.shared_with_group)
        else
          GroupBasicEntity.represent(group_link.shared_with_group, only: [:id])
        end
      end
    end

    expose :is_direct_member do |group_link, options|
      direct_member?(group_link, options)
    end

    expose :is_inherited_member do |group_link, options|
      !direct_member?(group_link, options)
    end

    private

    def can_read_shared_group?(group_link)
      can?(current_user, :read_shared_with_group, group_link)
    end

    def current_user
      options[:current_user]
    end

    def direct_member?(group_link, options)
      group_link.shared_from == options[:source]
    end
  end
end

GroupLink::GroupLinkEntity.prepend_mod
