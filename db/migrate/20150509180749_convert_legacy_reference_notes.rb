# Convert legacy Markdown-emphasized notes to the current, non-emphasized format
#
#   _mentioned in 54f7727c850972f0401c1312a7c4a6a380de5666_
#
# becomes
#
#   mentioned in 54f7727c850972f0401c1312a7c4a6a380de5666
class ConvertLegacyReferenceNotes < ActiveRecord::Migration
  def up
    execute %q{UPDATE notes SET note = trim(both '_' from note) WHERE system = true AND note LIKE '\_%\_'}
  end

  def down
    # noop
  end
end
