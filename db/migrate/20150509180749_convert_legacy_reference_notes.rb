# Convert legacy Markdown-emphasized notes to the current, non-emphasized format
#
#   _mentioned in 54f7727c850972f0401c1312a7c4a6a380de5666_
#
# becomes
#
#   mentioned in 54f7727c850972f0401c1312a7c4a6a380de5666
class ConvertLegacyReferenceNotes < ActiveRecord::Migration[4.2]
  def up
    quoted_column_name = ActiveRecord::Base.connection.quote_column_name('system')
    execute %Q{UPDATE notes SET note = trim(both '_' from note) WHERE #{quoted_column_name} = true AND note LIKE '\_%\_'}
  end

  def down
    # noop
  end
end
