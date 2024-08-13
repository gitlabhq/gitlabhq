# frozen_string_literal: true

module Integrations
  class Youtrack < BaseIssueTracker
    include Integrations::HasIssueTrackerFields
    include HasAvatar

    validates :project_url, :issues_url, presence: true, public_url: true, if: :activated?

    # {PROJECT-KEY}-{NUMBER} Examples: YT-1, PRJ-1, gl-030
    def reference_pattern(only_long: false)
      return @reference_pattern if defined?(@reference_pattern)

      regex_suffix = "|(#{Issue.reference_prefix}#{Gitlab::Regex.issue})"
      @reference_pattern = /(?<issue>\b[A-Za-z][A-Za-z0-9_]*-\d+\b)#{regex_suffix if only_long}/
    end

    def self.title
      'JetBrains YouTrack'
    end

    def self.description
      s_("IssueTracker|Use JetBrains YouTrack as this project's issue tracker.")
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/youtrack', s_("IssueTracker|Use JetBrains YouTrack as this project's issue tracker.")
      )
    end

    def self.to_param
      'youtrack'
    end

    def self.fields
      super.select { %w[project_url issues_url].include?(_1.name) }
    end

    def self.attribution_notice
      'Copyright © 2024 JetBrains s.r.o. JetBrains YouTrack and the JetBrains YouTrack logo are registered trademarks of JetBrains s.r.o.'
    end
  end
end
