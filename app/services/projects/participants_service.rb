module Projects
  class ParticipantsService < BaseService
    def initialize(project)
      @project = project
    end

    def execute(note_type, note_id)
      participating = if note_type && note_id
                      participants_in(note_type, note_id)
                    else
                      []
                    end
      team_members = sorted(@project.team.members)
      participants = all_members + team_members + participating
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
      users.uniq.to_a.compact.sort_by(&:username).map { |user| { username: user.username, name: user.name } }
    end

    def all_members
      [{ username: "all", name: "Project and Group Members" }]
    end
  end
end
