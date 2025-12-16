# frozen_string_literal: true

class TruncateUploads9ba88c4165 < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    # NOTE: following https://docs.gitlab.com/development/migration_style_guide/#truncate-a-table
    #   and the proposal in https://gitlab.com/gitlab-org/gitlab/-/issues/398199#proposal
    truncate_tables!('uploads_9ba88c4165')
  end

  def down
    # no-op
  end
end
