# frozen_string_literal: true

class FinalizePushEventPayloadsBigintConversion2 < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    # no-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5256
  end

  def down
    # no-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5256
  end
end
