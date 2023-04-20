# frozen_string_literal: true

class AllowNullFileMd5ToDebianGroupComponentFiles < Gitlab::Database::Migration[2.1]
  def up
    change_column_null :packages_debian_group_component_files, :file_md5, true
  end

  def down
    # There may now be nulls in the table, so we cannot re-add the constraint here.
  end
end
