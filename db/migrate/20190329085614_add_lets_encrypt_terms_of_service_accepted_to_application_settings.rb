# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLetsEncryptTermsOfServiceAcceptedToApplicationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :lets_encrypt_terms_of_service_accepted, :boolean, default: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :application_settings, :lets_encrypt_terms_of_service_accepted
  end
end
