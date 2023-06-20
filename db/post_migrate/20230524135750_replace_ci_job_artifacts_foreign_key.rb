# frozen_string_literal: true

class ReplaceCiJobArtifactsForeignKey < Gitlab::Database::Migration[2.1]
  def up
    # This migration was skipped in the ci database on gitlab.com as part of
    # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/14888
  end

  def down
    # This migration was skipped in the ci database on gitlab.com as part of
    # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/14888
  end
end
