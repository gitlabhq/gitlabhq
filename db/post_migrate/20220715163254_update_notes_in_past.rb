# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateNotesInPast < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    loop do
      update_count = define_batchable_model('notes')
        .where('created_at < ?', '1970-01-01').limit(100)
        .update_all(created_at: '1970-01-01 00:00:00')

      break if update_count == 0
    end
  end

  def down
    # no op
  end
end
