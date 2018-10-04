class DisallowBlankLineCodeOnNote < ActiveRecord::Migration
  def up
    execute("UPDATE notes SET line_code = NULL WHERE line_code = ''")
  end

  def down
    # noop
  end
end
