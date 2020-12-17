# frozen_string_literal: true

module Users
  module ParticipableService
    extend ActiveSupport::Concern

    included do
      attr_reader :noteable
    end

    private

    def noteable_owner
      return [] unless noteable && noteable.author.present?

      [noteable.author].tap do |users|
        preload_status(users)
      end
    end

    def participants_in_noteable
      return [] unless noteable

      users = noteable.participants(current_user)
      sorted(users)
    end

    def sorted(users)
      users.uniq.to_a.compact.sort_by(&:username).tap do |users|
        preload_status(users)
      end
    end

    def groups
      current_user.authorized_groups.with_route.sort_by(&:path)
    end

    def render_participants_as_hash(participants)
      participants.map(&method(:participant_as_hash))
    end

    def participant_as_hash(participant)
      case participant
      when Group
        group_as_hash(participant)
      when User
        user_as_hash(participant)
      else
        participant
      end
    end

    def user_as_hash(user)
      {
        type: user.class.name,
        username: user.username,
        name: user.name,
        avatar_url: user.avatar_url,
        availability: lazy_user_availability(user).itself # calling #itself to avoid returning a BatchLoader instance
      }
    end

    def group_as_hash(group)
      {
        type: group.class.name,
        username: group.full_path,
        name: group.full_name,
        avatar_url: group.avatar_url,
        count: group_counts.fetch(group.id, 0),
        mentionsDisabled: group.mentions_disabled
      }
    end

    def group_counts
      @group_counts ||= GroupMember
        .of_groups(current_user.authorized_groups)
        .non_request
        .count_users_by_group_id
    end

    def preload_status(users)
      users.each { |u| lazy_user_availability(u) }
    end

    def lazy_user_availability(user)
      BatchLoader.for(user.id).batch do |user_ids, loader|
        user_ids.each_slice(1_000) do |sliced_user_ids|
          UserStatus
            .select(:user_id, :availability)
            .primary_key_in(sliced_user_ids)
            .each { |status| loader.call(status.user_id, status.availability) }
        end
      end
    end
  end
end
