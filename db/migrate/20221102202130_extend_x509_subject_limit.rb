# frozen_string_literal: true

class ExtendX509SubjectLimit < Gitlab::Database::Migration[2.0]
  def up
    change_column :x509_certificates, :subject, :string, limit: 512
  end

  def down
    change_column :x509_certificates, :subject, :string, limit: 255
  end
end
