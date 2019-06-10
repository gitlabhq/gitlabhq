# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class GenerateLetsEncryptPrivateKey < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # we now generate this key on the fly, but since this migration was merged to master, we don't remove it
  def up
  end

  def down
  end
end
