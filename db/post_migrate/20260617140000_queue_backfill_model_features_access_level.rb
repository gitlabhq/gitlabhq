# frozen_string_literal: true

# Disabled (no-op).
#
# This migration originally enqueued the BackfillModelFeaturesAccessLevel batched
# background migration. It is reverted together with the default change (!242424)
# so the backfill does not run, since the feature it supported is being rolled
# back and the backfill will be resubmitted later. Running it twice would be a
# confusing experience for self-managed and Dedicated.
#
# Left as a no-op (per the deleting migrations guidance) so it does not enqueue
# the backfill on environments where it has not yet run. Where it already ran,
# the BBM is removed by 20260625005917_delete_backfill_model_features_access_level.
class QueueBackfillModelFeaturesAccessLevel < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    # no-op
  end

  def down
    # no-op
  end
end
