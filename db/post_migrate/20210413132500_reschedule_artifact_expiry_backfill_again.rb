# frozen_string_literal: true

class RescheduleArtifactExpiryBackfillAgain < ActiveRecord::Migration[6.0]
  # This migration has been disabled as it was causing a regression bug for self instances
  # preventing artifact deletion, see https://gitlab.com/gitlab-org/gitlab/-/issues/355955

  def up
    # no-op
  end

  def down
    # no-op
  end
end
