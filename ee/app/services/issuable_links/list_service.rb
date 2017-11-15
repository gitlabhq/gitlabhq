module IssuableLinks
  class ListService
    include Gitlab::Routing

    attr_reader :issuable, :current_user

    def initialize(issuable, user)
      @issuable, @current_user = issuable, user
    end

    def execute
      issues.map do |referenced_issue|
        {
          id: referenced_issue.id,
          title: referenced_issue.title,
          state: referenced_issue.state,
          reference: reference(referenced_issue),
          path: project_issue_path(referenced_issue.project, referenced_issue.iid),
          destroy_relation_path: destroy_relation_path(referenced_issue)
        }
      end
    end

    private

    def destroy_relation_path(issue)
      raise NotImplementedError
    end

    def reference(issue)
      issue.to_reference(issuable.project)
    end
  end
end
