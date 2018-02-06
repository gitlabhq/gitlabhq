# rubocop:disable all
class SetTypeOnLegacyDiffNotes < ActiveRecord::Migration
  def change
    execute "UPDATE notes SET type = 'LegacyDiffNote' WHERE line_code IS NOT NULL"
  end
end
