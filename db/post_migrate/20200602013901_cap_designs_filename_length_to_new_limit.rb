# frozen_string_literal: true

class CapDesignsFilenameLengthToNewLimit < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  CHAR_LENGTH = 255
  MODIFIED_NAME = 'gitlab-modified-'
  MODIFIED_EXTENSION = '.jpg'

  def up
    arel_table = Arel::Table.new(:design_management_designs)

    # Design filenames larger than the limit will be renamed to "gitlab-modified-{id}.jpg",
    # which will be valid and unique. The design file itself will appear broken, as it is
    # understood that no designs with filenames that exceed this limit will be legitimate.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33565/diffs#note_355789080
    new_value_clause = Arel::Nodes::NamedFunction.new(
      'CONCAT',
      [
        Arel::Nodes.build_quoted(MODIFIED_NAME),
        arel_table[:id],
        Arel::Nodes.build_quoted(MODIFIED_EXTENSION)
      ]
    )
    where_clause = Arel::Nodes::NamedFunction.new(
      'CHAR_LENGTH',
      [arel_table[:filename]]
    ).gt(CHAR_LENGTH)

    update_arel = Arel::UpdateManager.new.table(arel_table)
                                         .set([[arel_table[:filename], new_value_clause]])
                                         .where(where_clause)

    ActiveRecord::Base.connection.execute(update_arel.to_sql)
  end

  def down
    # no-op : the original filename is lost forever
  end
end
