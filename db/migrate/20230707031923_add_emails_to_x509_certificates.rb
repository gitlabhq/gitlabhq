# frozen_string_literal: true

class AddEmailsToX509Certificates < Gitlab::Database::Migration[2.1]
  def change
    add_column :x509_certificates, :emails, :string, array: true, default: [], null: false
  end
end
