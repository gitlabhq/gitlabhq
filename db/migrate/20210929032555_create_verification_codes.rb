# frozen_string_literal: true

class CreateVerificationCodes < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  def up
    constraint_visitor_id_code = check_constraint_name('verification_codes', 'visitor_id_code', 'max_length')
    constraint_code = check_constraint_name('verification_codes', 'code', 'max_length')
    constraint_phone = check_constraint_name('verification_codes', 'phone', 'max_length')

    execute(<<~SQL)
      CREATE TABLE verification_codes (
        created_at timestamp with time zone NOT NULL DEFAULT NOW(),
        visitor_id_code text,
        code text,
        phone text,
        PRIMARY KEY (created_at, visitor_id_code, code, phone),
        CONSTRAINT #{constraint_visitor_id_code} CHECK ((char_length(visitor_id_code) <= 64)),
        CONSTRAINT #{constraint_code} CHECK ((char_length(code) <= 8)),
        CONSTRAINT #{constraint_phone} CHECK ((char_length(phone) <= 32))
      ) PARTITION BY RANGE (created_at);
      COMMENT ON TABLE verification_codes IS 'JiHu-specific table';

      CREATE UNIQUE INDEX index_verification_codes_on_phone_and_visitor_id_code ON verification_codes (visitor_id_code, phone, created_at);
      COMMENT ON INDEX index_verification_codes_on_phone_and_visitor_id_code IS 'JiHu-specific index';
    SQL

    min_date = Date.today - 1.month
    max_date = Date.today + 1.month
    create_daterange_partitions('verification_codes', 'created_at', min_date, max_date)
  end

  def down
    drop_table :verification_codes
  end
end
