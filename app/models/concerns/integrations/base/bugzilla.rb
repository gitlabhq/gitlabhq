# frozen_string_literal: true

module Integrations
  module Base
    module Bugzilla
      extend ActiveSupport::Concern

      class_methods do
        def title
          'Bugzilla'
        end

        def description
          s_("IssueTracker|Use Bugzilla as this project's issue tracker.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/bugzilla.md', s_("IssueTracker|Use Bugzilla as this project's issue tracker.")
          )
        end

        def to_param
          'bugzilla'
        end

        def attribution_notice
          _('The Bugzilla logo is a trademark of the Mozilla Foundation in the U.S. and other countries.')
        end
      end

      included do
        include Base::IssueTracker
        include Integrations::HasIssueTrackerFields
        include HasAvatar

        validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?
      end
    end
  end
end
