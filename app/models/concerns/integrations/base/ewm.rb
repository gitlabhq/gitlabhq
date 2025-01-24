# frozen_string_literal: true

module Integrations
  module Base
    module Ewm
      extend ActiveSupport::Concern

      include Base::IssueTracker
      include HasIssueTrackerFields

      class_methods do
        def title
          'EWM'
        end

        def description
          s_("IssueTracker|Use IBM Engineering Workflow Management as this project's issue tracker.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/ewm.md',
            s_("IssueTracker|Use IBM Engineering Workflow Management as this project's issue tracker.")
          )
        end

        def to_param
          'ewm'
        end
      end

      included do
        validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

        def reference_pattern(*)
          @reference_pattern ||= %r{(?<issue>\b(?:bug|task|work item|workitem|rtcwi|defect)\b\s+\d+)}i
        end

        def issue_url(iid)
          issues_url.gsub(':id', iid.to_s.split(' ')[-1])
        end
      end
    end
  end
end
