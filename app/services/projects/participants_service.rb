module Projects
  class ParticipantsService < BaseService
    def execute(note_type, note_id)
      participating =
        if note_type && note_id
          participants_in(note_type, note_id)
        else
          []
        end
      project_members = sorted(project.team.members)
      participants = all_members + groups + project_members + participating
      participants.uniq
    end

    def participants_in(type, id)
      target = 
        case type
        when "Issue"
          project.issues.find_by_iid(id)
        when "MergeRequest"
          project.merge_requests.find_by_iid(id)
        when "Commit"
          project.commit(id)
        end
        
      return [] unless target

      users = target.participants(current_user)
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
