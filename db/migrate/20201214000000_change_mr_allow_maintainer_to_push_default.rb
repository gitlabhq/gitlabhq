# frozen_string_literal: true

class ChangeMrAllowMaintainerToPushDefault < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :merge_requests, :allow_maintainer_to_push, from: nil, to: true
    end
  end

  def down
    with_lock_retries do
      change_column_default :merge_requests, :allow_maintainer_to_push, from: true, to: nil
    end
  end
end
