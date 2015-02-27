module Projects
  class ParticipantsService < BaseService
    def initialize(project, user)
      @project  = project
      @user     = user
    end

    def execute(note_type, note_id)
      participating =
        if note_type && note_id
          participants_in(note_type, note_id)
        else
          []
        end
      team_members = sorted(@project.team.members)
      participants = all_members + groups + team_members + participating
      participants.uniq
    end

    def participants_in(type, id)
      users = case type
              when "Issue"
                issue = @project.issues.find_by_iid(id)
                issue ? issue.participants : []
              when "MergeRequest"
                merge_request = @project.merge_requests.find_by_iid(id)
                merge_request ? merge_request.participants : []
              when "Commit"
                author_ids = Note.for_commit_id(id).pluck(:author_id).uniq
                User.where(id: author_ids)
              else
                []
              end
      sorted(users)
    end

    def sorted(users)
      users.uniq.to_a.compact.sort_by(&:username).map do |user| 
        { username: user.username, name: user.name }
      end
    end

    def groups
      @user.authorized_groups.sort_by(&:path).map do |group| 
        count = group.users.count
        { username: group.path, name: "#{group.name} (#{count})" }
      end
    end

    def all_members
      count = @project.team.members.flatten.count
      [{ username: "all", name: "All Project and Group Members (#{count})" }]
    end
  end
end
