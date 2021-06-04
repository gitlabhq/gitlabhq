# frozen_string_literal: true

module Integrations
  class Redmine < BaseIssueTracker
    include ActionView::Helpers::UrlHelper
    validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

    def title
      'Redmine'
    end

    def description
      s_("IssueTracker|Use Redmine as this project's issue tracker.")
    end

    def help
      docs_link = link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/redmine'), target: '_blank', rel: 'noopener noreferrer'
      s_('IssueTracker|Use Redmine as the issue tracker. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'redmine'
    end
  end
end
