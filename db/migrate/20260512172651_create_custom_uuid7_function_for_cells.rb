# frozen_string_literal: true

class CreateCustomUuid7FunctionForCells < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION gen_random_uuid_v7() RETURNS uuid AS $$
      DECLARE
        ts_ms bigint;
        sub_ms int;
        unix_ts_ms bytea;
        uuid_bytes bytea;
        now_epoch double precision;
      BEGIN
        now_epoch := extract(epoch from clock_timestamp()) * 1000;
        ts_ms := floor(now_epoch)::bigint;
        sub_ms := floor((now_epoch - ts_ms) * 4096)::int;

        unix_ts_ms := substring(int8send(ts_ms) from 3);
        uuid_bytes := uuid_send(gen_random_uuid());
        uuid_bytes := overlay(uuid_bytes placing unix_ts_ms from 1 for 6);

        uuid_bytes := set_byte(uuid_bytes, 6, ((sub_ms >> 8) & x'0F'::int) | x'70'::int);
        uuid_bytes := set_byte(uuid_bytes, 7, sub_ms & x'FF'::int);

        RETURN encode(uuid_bytes, 'hex')::uuid;
      END
      $$ LANGUAGE plpgsql VOLATILE PARALLEL SAFE;
    SQL
  end

  def down
    execute 'DROP FUNCTION IF EXISTS gen_random_uuid_v7();'
  end
end
