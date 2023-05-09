# frozen_string_literal: true

class ConvertCiBuildsToListPartitioning < Gitlab::Database::Migration[2.1]
  def up
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/13818
  end

  def down
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/13818
  end
end
