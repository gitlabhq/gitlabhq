class PagesDomainsVerificationGracePeriod < ActiveRecord::Migration
  DOWNTIME = false

  class PagesDomain < ActiveRecord::Base
    include EachBatch
  end

  # Allow this migration to resume if it fails partway through
  disable_ddl_transaction!

  def up
    now = Time.now
    grace = now + 30.days

    PagesDomain.each_batch do |relation|
      relation.update_all(verified_at: now, enabled_until: grace)

      # Sleep 2 minutes between batches to not overload the DB with dead tuples
      sleep(2.minutes) unless relation.reorder(:id).last == PagesDomain.reorder(:id).last
    end
  end

  def down
    # no-op
  end
end
