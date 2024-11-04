# frozen_string_literal: true

module Users
  module ParticipableService
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    SEARCH_LIMIT = 10

    included do
      attr_reader :noteable
    end

    private

    def noteable_owner
      return [] unless noteable && noteable.author.present?
      return [] if noteable.author.placeholder? || noteable.author.import_user?

      [noteable.author].tap do |users|
        preload_status(users)
      end
    end

    def participants_in_noteable
      return [] unless noteable

      users = noteable.participants(current_user)
      users = users.reject { |user| user.placeholder? || user.import_user? }
      sorted(users)
    end

    def filter_and_sort_users(users_relation)
      if params[:search]
        users_relation.gfm_autocomplete_search(params[:search]).limit(SEARCH_LIMIT).tap do |users|
          preload_status(users)
        end
      else
        sorted(users_relation)
      end
    end

    def sorted(users)
      users.uniq.to_a.compact.sort_by(&:username).tap do |users|
        preload_status(users)
      end
    end

    def relation_at_search_limit?(users_relation)
      params[:search] && users_relation.size >= SEARCH_LIMIT
    end

    def groups
      return [] unless current_user

      relation = current_user.authorized_groups

      if params[:search]
        relation.gfm_autocomplete_search(params[:search]).limit(SEARCH_LIMIT).to_a
      else
        relation.with_route.sort_by(&:full_path)
      end
    end
    strong_memoize_attr :groups

    def render_participants_as_hash(participants)
      participants.map { |participant| participant_as_hash(participant) }
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
      groups_for_count = params[:search] ? groups : current_user.authorized_groups

      GroupMember
        .of_groups(groups_for_count)
        .non_request
        .count_users_by_group_id
    end
    strong_memoize_attr :group_counts

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
