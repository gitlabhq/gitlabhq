# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateX509Signatures < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :x509_issuers do |t|
      t.timestamps_with_timezone null: false

      t.string :subject_key_identifier, index: true, null: false, unique: true, limit: 255
      t.string :subject, null: false, limit: 255
      t.string :crl_url, null: false, limit: 255
    end

    create_table :x509_certificates do |t|
      t.timestamps_with_timezone null: false

      t.string :subject_key_identifier, index: true, null: false, unique: true, limit: 255
      t.string :subject, null: false, limit: 255
      t.string :email, null: false, limit: 255
      t.binary :serial_number, null: false

      t.integer :certificate_status, limit: 2, default: 0, null: false

      t.references :x509_issuer, index: true, null: false, foreign_key: { on_delete: :cascade }
    end

    create_table :x509_commit_signatures do |t|
      t.timestamps_with_timezone null: false

      t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.references :x509_certificate, index: true, null: false, foreign_key: { on_delete: :cascade }

      t.binary :commit_sha, index: true, null: false
      t.integer :verification_status, limit: 2, default: 0, null: false
    end
  end
  # rubocop:enable Migration/PreventStrings
end
