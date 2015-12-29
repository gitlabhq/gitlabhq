# Migration type: online without errors (works on previous version and new one)
class RenameEmojis < ActiveRecord::Migration
  def up
    # Renames aliases to main names
    execute("UPDATE notes SET note ='thumbsup' WHERE is_award = true AND note = '+1'")
    execute("UPDATE notes SET note ='thumbsdown' WHERE is_award = true AND note = '-1'")
    execute("UPDATE notes SET note ='poop' WHERE is_award = true AND note = 'shit'")
  end

  def down
    execute("UPDATE notes SET note ='+1' WHERE is_award = true AND note = 'thumbsup'")
    execute("UPDATE notes SET note ='-1' WHERE is_award = true AND note = 'thumbsdown'")
    execute("UPDATE notes SET note ='shit' WHERE is_award = true AND note = 'poop'")
  end
end
