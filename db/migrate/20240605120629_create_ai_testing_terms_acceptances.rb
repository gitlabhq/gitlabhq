# frozen_string_literal: true

class CreateAiTestingTermsAcceptances < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    create_table :ai_testing_terms_acceptances, id: false do |t|
      t.datetime_with_timezone :created_at, null: false

      t.bigint :user_id, null: false, primary_key: true, default: nil, index: false
      t.text :user_email, null: false, limit: 255
    end
  end
end
