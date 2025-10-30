# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanUpBigintConversionForMergeRequestDiffs < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  TABLE = :merge_request_diffs
  COLUMNS = %i[id merge_request_id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no op
  end
end
