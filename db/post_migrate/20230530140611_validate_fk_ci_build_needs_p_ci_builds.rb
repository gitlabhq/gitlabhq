# frozen_string_literal: true

class ValidateFkCiBuildNeedsPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_build_needs, nil, name: :temp_fk_rails_3cf221d4ed_p
  end

  def down
    # no-op
  end
end
