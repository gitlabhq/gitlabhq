# frozen_string_literal: true

module Users
  module ParticipableService
    extend ActiveSupport::Concern

    included do
      attr_reader :noteable
    end

    def noteable_owner
      return [] unless noteable && noteable.author.present?

      [user_as_hash(noteable.author)]
    end

    def participants_in_noteable
      return [] unless noteable

      users = noteable.participants(current_user)
      sorted(users)
    end

    def sorted(users)
      users.uniq.to_a.compact.sort_by(&:username).map do |user|
        user_as_hash(user)
      end
    end

    def groups
      group_counts = GroupMember
                       .of_groups(current_user.authorized_groups)
                       .non_request
                       .count_users_by_group_id

      current_user.authorized_groups.with_route.sort_by(&:path).map do |group|
        group_as_hash(group, group_counts)
      end
    end

    private

    def user_as_hash(user)
      {
        type: user.class.name,
        username: user.username,
        name: user.name,
        avatar_url: user.avatar_url
      }
    end

    def group_as_hash(group, group_counts)
      {
        type: group.class.name,
        username: group.full_path,
        name: group.full_name,
        avatar_url: group.avatar_url,
        count: group_counts.fetch(group.id, 0),
        mentionsDisabled: group.mentions_disabled
      }
    end
  end
end
