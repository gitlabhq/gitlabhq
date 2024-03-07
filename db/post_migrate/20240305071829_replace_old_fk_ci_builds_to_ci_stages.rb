# frozen_string_literal: true

class ReplaceOldFkCiBuildsToCiStages < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def up
    # no-op
  end

  def down
    # no-op
  end
end
