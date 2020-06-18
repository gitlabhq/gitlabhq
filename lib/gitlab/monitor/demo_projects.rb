# frozen_string_literal: true

module Gitlab
  module Monitor
    # See Demo Project documentation
    # https://about.gitlab.com/handbook/engineering/development/ops/monitor/#demo-environments
    module DemoProjects
      # [https://gitlab.com/gitlab-org/monitor/tanuki-inc, https://gitlab.com/gitlab-org/monitor/monitor-sandbox]
      DOT_COM_IDS = [14986497, 12507547].freeze
      # [https://staging.gitlab.com/gitlab-org/monitor/monitor-sandbox]
      STAGING_IDS = [4422333].freeze

      def self.primary_keys
        # .com? returns true for staging
        if ::Gitlab.com? && !::Gitlab.staging?
          DOT_COM_IDS
        elsif ::Gitlab.staging?
          STAGING_IDS
        elsif ::Gitlab.dev_or_test_env?
          Project.limit(100).pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
        else
          []
        end
      end
    end
  end
end
