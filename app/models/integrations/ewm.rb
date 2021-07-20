# frozen_string_literal: true

module Integrations
  class Ewm < BaseIssueTracker
    include ActionView::Helpers::UrlHelper

    validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

    def self.reference_pattern(only_long: true)
      @reference_pattern ||= %r{(?<issue>\b(bug|task|work item|workitem|rtcwi|defect)\b\s+\d+)}i
    end

    def title
      'EWM'
    end

    def description
      s_("IssueTracker|Use IBM Engineering Workflow Management as this project's issue tracker.")
    end

    def help
      docs_link = link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/ewm'), target: '_blank', rel: 'noopener noreferrer'
      s_("IssueTracker|Use IBM Engineering Workflow Management as this project's issue tracker. %{docs_link}").html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'ewm'
    end

    def testable?
      false
    end

    def issue_url(iid)
      issues_url.gsub(':id', iid.to_s.split(' ')[-1])
    end
  end
end
