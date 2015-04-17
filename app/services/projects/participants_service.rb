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
      users = 
        case type
        when "Issue"
          issue = project.issues.find_by_iid(id)
          issue.participants(current_user) if issue
        when "MergeRequest"
          merge_request = project.merge_requests.find_by_iid(id)
          merge_request.participants(current_user) if merge_request
        when "Commit"
          commit = project.repository.commit(id)
          commit.participants(project, current_user) if commit
        end

      return [] unless users
      
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
        { username: group.path, name: "#{group.name} (#{count})" }
      end
    end

    def all_members
      count = project.team.members.flatten.count
      [{ username: "all", name: "All Project and Group Members (#{count})" }]
    end
  end
end
