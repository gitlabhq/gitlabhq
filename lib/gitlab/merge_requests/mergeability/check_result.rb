# frozen_string_literal: true
module Gitlab
  module MergeRequests
    module Mergeability
      class CheckResult
        SUCCESS_STATUS = :success
        FAILED_STATUS = :failed

        attr_reader :status, :payload

        def self.default_payload
          { last_run_at: Time.current }
        end

        def self.success(payload: {})
          new(status: SUCCESS_STATUS, payload: default_payload.merge(**payload))
        end

        def self.failed(payload: {})
          new(status: FAILED_STATUS, payload: default_payload.merge(**payload))
        end

        def self.from_hash(data)
          new(
            status: data.fetch(:status).to_sym,
            payload: data.fetch(:payload))
        end

        def initialize(status:, payload: {})
          @status = status
          @payload = payload
        end

        def to_hash
          { status: status, payload: payload }
        end

        def failed?
          status == FAILED_STATUS
        end

        def success?
          status == SUCCESS_STATUS
        end
      end
    end
  end
end
