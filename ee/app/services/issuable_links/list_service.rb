module IssuableLinks
  class ListService
    include Gitlab::Routing

    attr_reader :issuable, :current_user

    def initialize(issuable, user)
      @issuable, @current_user = issuable, user
    end

    def execute
      issues.map do |referenced_issue|
        to_hash(referenced_issue)
      end
    end

    private

    def reference(issue)
      issue.to_reference(issuable.project)
    end

    def to_hash(issue)
      {
        id: issue.id,
        title: issue.title,
        state: issue.state,
        reference: reference(issue),
        path: project_issue_path(issue.project, issue.iid)
      }
    end
  end
end
