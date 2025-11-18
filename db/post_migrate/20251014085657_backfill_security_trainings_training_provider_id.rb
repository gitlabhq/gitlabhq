# frozen_string_literal: true

class BackfillSecurityTrainingsTrainingProviderId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    # no-op
    # We had to no-op this migration as it was causing a broken master
  end

  def down
    # no-op
  end
end
