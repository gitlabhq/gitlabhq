# frozen_string_literal: true

class RemoveCrlNull < Gitlab::Database::Migration[2.1]
  def up
    change_column_null :x509_certificates, :subject, true
    change_column_null :x509_issuers, :subject, true
    change_column_null :x509_issuers, :crl_url, true
  end

  def down
    change_column_null :x509_certificates, :subject, false
    change_column_null :x509_issuers, :subject, false
    change_column_null :x509_issuers, :crl_url, false
  end
end
