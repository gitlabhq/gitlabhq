# frozen_string_literal: true

module Integrations
  module Base
    module Redmine
      extend ActiveSupport::Concern

      include Base::IssueTracker
      include Integrations::HasIssueTrackerFields

      class_methods do
        def title
          'Redmine'
        end

        def description
          s_("IssueTracker|Use Redmine as this project's issue tracker.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/redmine.md',
            s_("IssueTracker|Use Redmine as the issue tracker.")
          )
        end

        def to_param
          'redmine'
        end
      end

      included do
        validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?
      end
    end
  end
end
