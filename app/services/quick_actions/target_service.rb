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

    # rubocop: disable CodeReuse/ActiveRecord
    def issue(type_id)
      return project.issues.build if type_id.nil?

      IssuesFinder.new(current_user, project_id: project.id).find_by(iid: type_id) || project.issues.build
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_request(type_id)
      return project.merge_requests.build if type_id.nil?

      MergeRequestsFinder.new(current_user, project_id: project.id).find_by(iid: type_id) || project.merge_requests.build
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def commit(type_id)
      project.commit(type_id)
    end
  end
end

QuickActions::TargetService.prepend_mod_with('QuickActions::TargetService')
