# frozen_string_literal: true

class PruneOldEventsWorker
  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    # Contribution calendar shows maximum 12 months of events.
    # Double nested query is used because MySQL doesn't allow DELETE subqueries
    # on the same table.
    Event.unscoped.where(
      '(id IN (SELECT id FROM (?) ids_to_remove))',
      Event.unscoped.where(
        'created_at < ?',
        (12.months + 1.day).ago)
      .select(:id)
      .limit(10_000))
    .delete_all
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
