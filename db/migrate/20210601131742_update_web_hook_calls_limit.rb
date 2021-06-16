# frozen_string_literal: true

class UpdateWebHookCallsLimit < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('web_hook_calls', 'free', 120)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('web_hook_calls', 'free', 0)
  end
end
