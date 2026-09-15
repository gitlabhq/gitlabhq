# frozen_string_literal: true

module Gitlab
  module Organizations
    module TransferSupportRegistry
      REGISTRY_PATH = 'config/organizations/transfer_support.yml'
      VALID_STATUSES = %w[supported no_work_needed].freeze
      # Issues are always project-scoped (gitlab-org/gitlab/-/issues or /-/work_items), never
      # group-scoped. Group-level work items (epics) only exist at /-/work_items, never /-/issues.
      ISSUE_URL_REGEXP =
        %r{\Ahttps://gitlab\.com/(?:gitlab-org/gitlab/-/(?:issues|work_items)|groups/gitlab-org/-/work_items)/\d+\z}

      class << self
        def status_for(table_name)
          registry[table_name]
        end

        def registry
          @registry ||= YAML.safe_load_file(Rails.root.join(REGISTRY_PATH))
        end

        def valid_status?(status)
          VALID_STATUSES.include?(status) || status.to_s.match?(ISSUE_URL_REGEXP)
        end
      end
    end
  end
end
