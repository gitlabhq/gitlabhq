# frozen_string_literal: true

class AddUniqueIndexToSystemNoteMetadataOnIdConvertToBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  def up
    # no-op
    # The index has been created asynchronously for GitLab.com
    # The index is going to be used to back a primary key and a foreign key.
    # Dropping the index would require dropping any foreign key associated with the index
    # thus the index and the foreign key must be added in the same migration.
  end

  def down
    # no-op
  end
end
