# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateHolderNameLimit < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :user_credit_card_validations, :holder_name, 50, constraint_name: new_constraint_name
    remove_text_limit :user_credit_card_validations, :holder_name, constraint_name: old_constraint_name
  end

  def down
    add_text_limit :user_credit_card_validations, :holder_name, 26, validate: false, constraint_name: old_constraint_name
    remove_text_limit :user_credit_card_validations, :holder_name, constraint_name: new_constraint_name
  end

  private

  def old_constraint_name
    check_constraint_name(:user_credit_card_validations, :holder_name, 'max_length')
  end

  def new_constraint_name
    check_constraint_name(:user_credit_card_validations, :holder_name, 'max_length_50')
  end
end
