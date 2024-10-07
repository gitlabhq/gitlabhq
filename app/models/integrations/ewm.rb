# frozen_string_literal: true

module Integrations
  class Ewm < BaseIssueTracker
    include HasIssueTrackerFields

    validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

    def reference_pattern(only_long: true)
      @reference_pattern ||= %r{(?<issue>\b(bug|task|work item|workitem|rtcwi|defect)\b\s+\d+)}i
    end

    def self.title
      'EWM'
    end

    def self.description
      s_("IssueTracker|Use IBM Engineering Workflow Management as this project's issue tracker.")
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/ewm.md',
        s_("IssueTracker|Use IBM Engineering Workflow Management as this project's issue tracker.")
      )
    end

    def self.to_param
      'ewm'
    end

    def issue_url(iid)
      issues_url.gsub(':id', iid.to_s.split(' ')[-1])
    end
  end
end
