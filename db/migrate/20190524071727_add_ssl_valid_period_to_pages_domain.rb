# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSslValidPeriodToPagesDomain < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :pages_domains, :certificate_valid_not_before, :datetime_with_timezone
    add_column :pages_domains, :certificate_valid_not_after, :datetime_with_timezone
  end
end
