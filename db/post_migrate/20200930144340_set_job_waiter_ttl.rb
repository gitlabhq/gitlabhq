# frozen_string_literal: true

class SetJobWaiterTtl < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  SCRIPT = <<~LUA
    if redis.call("ttl", KEYS[1]) < 0 then
      redis.call("expire", KEYS[1], 21600)
    end
  LUA

  def up
    Gitlab::Redis::SharedState.with do |redis|
      cursor_init = '0'
      cursor = cursor_init

      loop do
        cursor, keys = redis.scan(cursor, match: 'gitlab:job_waiter:*')

        redis.pipelined do |redis|
          keys.each { |k| redis.eval(SCRIPT, keys: [k]) }
        end

        break if cursor == cursor_init
      end
    end
  end

  def down
  end
end
