# frozen_string_literal: true

class SetLimitForRateLimitingResponseText < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :rate_limiting_response_text, 255
  end

  def down
    remove_text_limit :application_settings, :rate_limiting_response_text
  end
end
