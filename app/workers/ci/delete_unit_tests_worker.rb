# frozen_string_literal: true

module Ci
  class DeleteUnitTestsWorker
    include ApplicationWorker

    data_consistency :sticky
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :code_testing
    idempotent!

    def perform
      Ci::DeleteUnitTestsService.new.execute
    end
  end
end
