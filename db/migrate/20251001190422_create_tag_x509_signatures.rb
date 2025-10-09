# frozen_string_literal: true

class CreateTagX509Signatures < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    create_table :tag_x509_signatures do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in spec/factories/repositories/tags/x509_signatures.rb
      t.bigint :project_id, null: false
      t.bigint :x509_certificate_id, index: true, null: false
      t.timestamps_with_timezone null: false
      t.integer :verification_status, null: false, default: 0, limit: 2
      t.binary :object_name, null: false
    end
  end
end
