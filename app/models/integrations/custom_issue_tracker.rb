# frozen_string_literal: true

module Integrations
  class CustomIssueTracker < BaseIssueTracker
    include HasIssueTrackerFields

    validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

    def self.title
      s_('IssueTracker|Custom issue tracker')
    end

    def self.description
      s_("IssueTracker|Use a custom issue tracker as this project's issue tracker.")
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/custom_issue_tracker.md',
        s_("IssueTracker|Use a custom issue tracker that is not in the integration list.")
      )
    end

    def self.to_param
      'custom_issue_tracker'
    end
  end
end
