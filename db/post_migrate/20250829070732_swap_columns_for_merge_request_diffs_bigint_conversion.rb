# frozen_string_literal: true

class SwapColumnsForMergeRequestDiffsBigintConversion < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20518
  def up
    # no-op
  end

  def down
    # no-op
  end
end
