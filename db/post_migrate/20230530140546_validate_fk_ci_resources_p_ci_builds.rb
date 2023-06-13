# frozen_string_literal: true

class ValidateFkCiResourcesPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_resources, nil, name: :temp_fk_e169a8e3d5_p
  end

  def down
    # no-op
  end
end
