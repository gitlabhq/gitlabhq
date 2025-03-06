# frozen_string_literal: true

class IncreaseTokenEncryptedConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  TABLE_NAME = 'ci_runners_e59bb2812d'

  def up
    # rubocop:disable Layout/LineLength -- This is more readable
    add_text_limit TABLE_NAME, :token_encrypted, 512, constraint_name: check_constraint_name(TABLE_NAME, :token_encrypted, 'max_length_512')
    remove_text_limit TABLE_NAME, :token_encrypted, constraint_name: check_constraint_name(TABLE_NAME, :token_encrypted, 'max_length')
    # rubocop:enable Layout/LineLength
  end

  def down
    # no-op: Danger of failing if there are records with length(token_encrypted) > 128
  end
end
