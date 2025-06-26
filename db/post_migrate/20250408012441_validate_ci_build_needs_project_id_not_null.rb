# frozen_string_literal: true

class ValidateCiBuildNeedsProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    # no-op due to issue https://gitlab.com/gitlab-org/gitlab/-/issues/548685
  end

  def down
    # no-op
  end
end
