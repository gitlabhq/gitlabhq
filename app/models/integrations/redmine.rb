# frozen_string_literal: true

module Integrations
  class Redmine < BaseIssueTracker
    include Integrations::HasIssueTrackerFields

    validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

    def self.title
      'Redmine'
    end

    def self.description
      s_("IssueTracker|Use Redmine as this project's issue tracker.")
    end

    def self.help
      build_help_page_url('user/project/integrations/redmine.md', s_("IssueTracker|Use Redmine as the issue tracker."))
    end

    def self.to_param
      'redmine'
    end
  end
end
