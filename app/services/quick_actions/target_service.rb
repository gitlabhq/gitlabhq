# frozen_string_literal: true

module QuickActions
  class TargetService < BaseService
    def execute(type, type_id)
      case type&.downcase
      when 'issue'
        issue(type_id)
      when 'mergerequest'
        merge_request(type_id)
      when 'commit'
        commit(type_id)
      end
    end

    private

    def issue(type_id)
      IssuesFinder.new(current_user, project_id: project.id).find_by(iid: type_id) || project.issues.build
    end

    def merge_request(type_id)
      MergeRequestsFinder.new(current_user, project_id: project.id).find_by(iid: type_id) || project.merge_requests.build
    end

    def commit(type_id)
      return nil unless type_id

      project.commit(type_id)
    end
  end
end
