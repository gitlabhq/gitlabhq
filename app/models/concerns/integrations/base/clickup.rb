# frozen_string_literal: true

module Integrations
  module Base
    module Clickup
      extend ActiveSupport::Concern

      include Base::IssueTracker
      include HasIssueTrackerFields
      include HasAvatar

      FIELDS = %w[project_url issues_url].freeze

      class_methods do
        def title
          'ClickUp'
        end

        def description
          s_("IssueTracker|Use Clickup as this project's issue tracker.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/clickup.md',
            s_("IssueTracker|Use ClickUp as this project's issue tracker.")
          )
        end

        def to_param
          'clickup'
        end

        def fields
          super.select { |field| FIELDS.include?(field.name) }
        end
      end

      included do
        validates :project_url, :issues_url, presence: true, public_url: true, if: :activated?

        def reference_pattern(*)
          @reference_pattern ||= /(?:(?:#|CU-)(?<issue>[a-z0-9]+)|(?<issue>[A-Z0-9_]{2,10}-\d+))\b/
        end
      end
    end
  end
end
