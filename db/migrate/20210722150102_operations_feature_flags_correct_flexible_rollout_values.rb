# frozen_string_literal: true

class OperationsFeatureFlagsCorrectFlexibleRolloutValues < ActiveRecord::Migration[6.1]
  STICKINESS = { "USERID" => "userId", "RANDOM" => "random", "SESSIONID" => "sessionId", "DEFAULT" => "default" }.freeze

  def up
    STICKINESS.each do |before, after|
      update_statement = <<-SQL
        UPDATE operations_strategies
        SET parameters = parameters || jsonb_build_object('stickiness', '#{quote_string(after)}')
        WHERE name = 'flexibleRollout' AND parameters->>'stickiness' = '#{quote_string(before)}'
      SQL

      execute(update_statement)
    end
  end

  def down
    STICKINESS.each do |before, after|
      update_statement = <<-SQL
        UPDATE operations_strategies
        SET parameters = parameters || jsonb_build_object('stickiness', '#{quote_string(before)}')
        WHERE name = 'flexibleRollout' AND parameters->>'stickiness' = '#{quote_string(after)}'
      SQL

      execute(update_statement)
    end
  end
end
