# frozen_string_literal: true

module MergeRequests
  class MergeabilityCheckBatchService
    def initialize(merge_requests, user)
      @merge_requests = merge_requests
      @user = user
    end

    def execute
      return unless merge_requests.present?

      MergeRequests::MergeabilityCheckBatchWorker.perform_async(merge_requests.map(&:id), user&.id)
    end

    private

    attr_reader :merge_requests, :user
  end
end
