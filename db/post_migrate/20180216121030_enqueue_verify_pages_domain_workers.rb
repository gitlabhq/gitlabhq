class EnqueueVerifyPagesDomainWorkers < ActiveRecord::Migration
  class PagesDomain < ActiveRecord::Base
    include EachBatch
  end

  def up
    PagesDomain.each_batch do |relation|
      ids = relation.pluck(:id).map { |id| [id] }
      PagesDomainVerificationWorker.bulk_perform_async(ids)
    end
  end

  def down
    # no-op
  end
end
