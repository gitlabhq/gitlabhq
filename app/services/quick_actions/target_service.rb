# frozen_string_literal: true

module QuickActions
  class TargetService < BaseService
    def execute(type, type_iid)
      case type&.downcase
      when 'workitem'
        work_item(type_iid)
      when 'issue'
        issue(type_iid)
      when 'mergerequest'
        merge_request(type_iid)
      when 'commit'
        commit(type_iid)
      end
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def work_item(type_iid)
      WorkItems::WorkItemsFinder.new(current_user, project_id: project.id).find_by(iid: type_iid)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def issue(type_iid)
      return project.issues.build if type_iid.nil?

      IssuesFinder.new(current_user, project_id: project.id).find_by(iid: type_iid) || project.issues.build
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_request(type_iid)
      return project.merge_requests.build if type_iid.nil?

      MergeRequestsFinder.new(current_user, project_id: project.id).find_by(iid: type_iid) || project.merge_requests.build
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def commit(type_iid)
      project.commit(type_iid)
    end
  end
end

QuickActions::TargetService.prepend_mod_with('QuickActions::TargetService')
