module Users
  module ParticipableService
    extend ActiveSupport::Concern

    included do
      attr_reader :noteable
    end

    def noteable_owner
      return [] unless noteable && noteable.author.present?

      [as_hash(noteable.author)]
    end

    def participants_in_noteable
      return [] unless noteable

      users = noteable.participants(current_user)
      sorted(users)
    end

    def sorted(users)
      users.uniq.to_a.compact.sort_by(&:username).map do |user|
        as_hash(user)
      end
    end

    def groups
      current_user.authorized_groups.sort_by(&:path).map do |group|
        count = group.users.count
        { username: group.full_path, name: group.full_name, count: count, avatar_url: group.avatar_url }
      end
    end

    private

    def as_hash(user)
      { username: user.username, name: user.name, avatar_url: user.avatar_url }
    end
  end
end
