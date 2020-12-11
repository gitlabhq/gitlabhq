# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class ReportsComparer
        include Gitlab::Utils::StrongMemoize

        STATUS_SUCCESS = 'success'
        STATUS_FAILED = 'failed'

        attr_reader :base_report, :head_report

        def initialize(base_report, head_report)
          @base_report = base_report
          @head_report = head_report
        end

        def status
          success? ? STATUS_SUCCESS : STATUS_FAILED
        end

        def success?
          raise NotImplementedError
        end

        def existing_errors
          raise NotImplementedError
        end

        def new_errors
          raise NotImplementedError
        end

        def resolved_errors
          raise NotImplementedError
        end

        def errors_count
          raise NotImplementedError
        end

        def resolved_count
          resolved_errors.size
        end

        def total_count
          existing_errors.size + new_errors.size
        end
      end
    end
  end
end
