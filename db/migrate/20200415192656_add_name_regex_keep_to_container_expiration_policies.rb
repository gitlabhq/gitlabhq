# frozen_string_literal: true

class AddNameRegexKeepToContainerExpirationPolicies < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'container_expiration_policies_name_regex_keep'

  def up
    add_column(:container_expiration_policies, :name_regex_keep, :text)
    add_text_limit(:container_expiration_policies, :name_regex_keep, 255, constraint_name: CONSTRAINT_NAME)
  end

  def down
    remove_check_constraint(:container_expiration_policies, CONSTRAINT_NAME)
    remove_column(:container_expiration_policies, :name_regex_keep)
  end
end
