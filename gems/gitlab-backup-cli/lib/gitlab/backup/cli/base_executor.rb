# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      class BaseExecutor
        attr_reader :backup_bucket, :wait_for_completion, :registry_bucket, :service_account_file

        def initialize(backup_bucket:, wait_for_completion:, registry_bucket:, service_account_file:)
          @backup_bucket = backup_bucket
          @registry_bucket = registry_bucket
          @wait_for_completion = wait_for_completion
          @service_account_file = service_account_file
        end
      end
    end
  end
end
