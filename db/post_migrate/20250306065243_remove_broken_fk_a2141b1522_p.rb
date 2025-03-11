# frozen_string_literal: true

class RemoveBrokenFkA2141b1522P < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  # No-op for https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19464
  def up; end
  def down; end
end
