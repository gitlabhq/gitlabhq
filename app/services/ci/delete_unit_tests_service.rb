# frozen_string_literal: true

module Ci
  class DeleteUnitTestsService
    include EachBatch

    BATCH_SIZE = 100

    def execute
      purge_data!(Ci::UnitTestFailure)
      purge_data!(Ci::UnitTest)
    end

    private

    def purge_data!(klass)
      loop do
        break unless delete_batch!(klass)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def delete_batch!(klass)
      deleted = 0

      klass.transaction do
        ids = klass.deletable.lock('FOR UPDATE SKIP LOCKED').limit(BATCH_SIZE).pluck(:id)
        break if ids.empty?

        deleted = klass.where(id: ids).delete_all
      end

      deleted > 0
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
