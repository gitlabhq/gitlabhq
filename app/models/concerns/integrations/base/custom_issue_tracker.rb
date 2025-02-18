# frozen_string_literal: true

module Integrations
  module Base
    module CustomIssueTracker
      extend ActiveSupport::Concern

      include Base::IssueTracker
      include HasIssueTrackerFields

      class_methods do
        def title
          s_('IssueTracker|Custom issue tracker')
        end

        def description
          s_("IssueTracker|Use a custom issue tracker as this project's issue tracker.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/custom_issue_tracker.md',
            s_("IssueTracker|Use a custom issue tracker that is not in the integration list.")
          )
        end

        def to_param
          'custom_issue_tracker'
        end
      end

      included do
        validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?
      end
    end
  end
end
