# frozen_string_literal: true

class AddClaimedUntilToZoektTasks < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    # NULL on a processing row means the claim predates this column, so it is
    # treated as expired rather than as an unbounded claim.
    add_column :zoekt_tasks, :claimed_until, :datetime_with_timezone
  end
end
