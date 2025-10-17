# frozen_string_literal: true

class CreateDesignatedBeneficiariesTable < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    create_table :designated_beneficiaries do |t| # rubocop:disable Migration/EnsureFactoryForTable -- False positive
      t.references :user, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime_with_timezone :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.integer :type, null: false, limit: 2
      t.text :name, null: false, limit: 255
      t.text :relationship, limit: 255
      t.text :email, limit: 255
    end
  end

  def down
    drop_table :designated_beneficiaries
  end
end
