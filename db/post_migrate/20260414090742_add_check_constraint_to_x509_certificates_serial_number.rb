# frozen_string_literal: true

class AddCheckConstraintToX509CertificatesSerialNumber < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  TABLE_NAME = :x509_certificates
  CONSTRAINT_NAME = 'check_x509_certificates_serial_number_max_length'

  def up
    add_check_constraint(
      TABLE_NAME,
      'octet_length(serial_number) <= 25',
      CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end
end
