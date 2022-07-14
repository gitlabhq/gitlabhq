# frozen_string_literal: true

module Integrations
  class Youtrack < BaseIssueTracker
    include Integrations::HasIssueTrackerFields

    validates :project_url, :issues_url, presence: true, public_url: true, if: :activated?

    # {PROJECT-KEY}-{NUMBER} Examples: YT-1, PRJ-1, gl-030
    def self.reference_pattern(only_long: false)
      if only_long
        /(?<issue>\b[A-Za-z][A-Za-z0-9_]*-\d+\b)/
      else
        /(?<issue>\b[A-Za-z][A-Za-z0-9_]*-\d+\b)|(#{Issue.reference_prefix}#{Gitlab::Regex.issue})/
      end
    end

    def title
      'YouTrack'
    end

    def description
      s_("IssueTracker|Use YouTrack as this project's issue tracker.")
    end

    def help
      docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/youtrack'), target: '_blank', rel: 'noopener noreferrer'
      s_("IssueTracker|Use YouTrack as this project's issue tracker. %{docs_link}").html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'youtrack'
    end

    def fields
      super.select { _1.name.in?(%w[project_url issues_url]) }
    end
  end
end
