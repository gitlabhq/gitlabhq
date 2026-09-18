# frozen_string_literal: true

class DropQueryLogUsageMv < ClickHouse::Migration
  def up
    execute 'DROP VIEW IF EXISTS query_log_usage_mv'
  end
end
