# frozen_string_literal: true

module Integrations
  module Base
    module Youtrack
      extend ActiveSupport::Concern

      include Base::IssueTracker
      include Integrations::HasIssueTrackerFields
      include HasAvatar

      FIELDS = %w[project_url issues_url].freeze

      class_methods do
        def title
          'JetBrains YouTrack'
        end

        def description
          s_("IssueTracker|Use JetBrains YouTrack as this project's issue tracker.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/youtrack.md',
            s_("IssueTracker|Use JetBrains YouTrack as this project's issue tracker.")
          )
        end

        def to_param
          'youtrack'
        end

        def fields
          super.select { |field| FIELDS.include?(field.name) }
        end

        def attribution_notice
          'Copyright © 2024 JetBrains s.r.o. JetBrains YouTrack and the JetBrains ' \
            'YouTrack logo are registered trademarks of JetBrains s.r.o.'
        end
      end

      included do
        validates :project_url, :issues_url, presence: true, public_url: true, if: :activated?

        # {PROJECT-KEY}-{NUMBER} Examples: YT-1, PRJ-1, gl-030
        def reference_pattern(only_long: false)
          return @reference_pattern if defined?(@reference_pattern)

          regex_suffix = "|(#{Issue.reference_prefix}#{Gitlab::Regex.issue})"
          @reference_pattern = /(?<issue>\b[A-Za-z][A-Za-z0-9_]*-\d+\b)#{regex_suffix if only_long}/
        end
      end
    end
  end
end
