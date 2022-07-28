# frozen_string_literal: true

class DisableJobTokenScopeWhenUnused < Gitlab::Database::Migration[1.0]
  def up
    # no-op: Must have run before %"15.X" as it is not compatible with decomposed CI database
  end

  def down
    # no-op
  end
end
