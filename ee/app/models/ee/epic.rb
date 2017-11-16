module EE
  module Epic
    extend ActiveSupport::Concern

    prepended do
      include InternalId
      include Issuable
      include Noteable

      belongs_to :assignee, class_name: "User"
      belongs_to :group

      has_many :epic_issues

      validates :group, presence: true
    end

    def assignees
      Array(assignee)
    end

    def project
      nil
    end

    def supports_weight?
      false
    end

    # we don't support project epics for epics yet, planned in the future #4019
    def update_project_counter_caches
    end

    def issues(current_user)
      related_issues = ::Issue.select('issues.*, epic_issues.id as epic_issue_id')
        .joins(:epic_issue)
        .where("epic_issues.epic_id = #{id}")

      Ability.issues_readable_by_user(related_issues, current_user)
    end
  end
end
