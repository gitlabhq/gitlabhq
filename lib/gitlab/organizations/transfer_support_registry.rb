# frozen_string_literal: true

module Gitlab
  module Organizations
    module TransferSupportRegistry
      REGISTRY_PATH = 'config/organizations/transfer_support.yml'
      VALID_STATUSES = %w[supported todo no_work_needed].freeze

      class << self
        def status_for(table_name)
          registry[table_name]
        end

        def registry
          @registry ||= YAML.safe_load_file(Rails.root.join(REGISTRY_PATH))
        end
      end
    end
  end
end
