# frozen_string_literal: true

module Integrations
  class Bugzilla < BaseIssueTracker
    include Integrations::HasIssueTrackerFields
    include HasAvatar

    validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

    def self.title
      'Bugzilla'
    end

    def self.description
      s_("IssueTracker|Use Bugzilla as this project's issue tracker.")
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/bugzilla.md', s_("IssueTracker|Use Bugzilla as this project's issue tracker.")
      )
    end

    def self.to_param
      'bugzilla'
    end

    def self.attribution_notice
      _('The Bugzilla logo is a trademark of the Mozilla Foundation in the U.S. and other countries.')
    end
  end
end
