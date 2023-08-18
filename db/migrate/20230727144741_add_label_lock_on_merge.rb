# frozen_string_literal: true

class AddLabelLockOnMerge < Gitlab::Database::Migration[2.1]
  def change
    # no-op as this caused an incident
    # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16134
    # add_column :labels, :lock_on_merge, :boolean, default: false, null: false
  end
end
