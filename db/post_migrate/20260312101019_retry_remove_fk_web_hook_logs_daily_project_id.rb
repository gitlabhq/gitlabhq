# frozen_string_literal: true

class RetryRemoveFkWebHookLogsDailyProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    # noop: lock timeout happened during deployment
  end

  def down
    # noop
  end
end
