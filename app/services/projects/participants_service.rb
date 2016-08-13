module Projects
  class ParticipantsService < BaseService
    attr_reader :noteable
    
    def execute(noteable)
      @noteable = noteable

      project_members = sorted(project.team.members)
      participants = noteable_owner + participants_in_noteable + all_members + groups + project_members
      participants.uniq
    end

    def noteable_owner
      return [] unless noteable && noteable.author.present?

      [{
        name: noteable.author.name,
        username: noteable.author.username
      }]
    end

    def participants_in_noteable
      return [] unless noteable

      users = noteable.participants(current_user)
      sorted(users)
    end

    def sorted(users)
      users.uniq.to_a.compact.sort_by(&:username).map do |user|
        { username: user.username, name: user.name }
      end
    end

    def groups
      current_user.authorized_groups.sort_by(&:path).map do |group|
        count = group.users.count
        { username: group.path, name: group.name, count: count }
      end
    end

    def all_members
      count = project.team.members.flatten.count
      [{ username: "all", name: "All Project and Group Members", count: count }]
    end
  end
end
