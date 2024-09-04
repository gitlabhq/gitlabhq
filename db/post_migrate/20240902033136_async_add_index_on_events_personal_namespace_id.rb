# frozen_string_literal: true

class AsyncAddIndexOnEventsPersonalNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    # no-op due to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18501
  end

  def down
    # no-op due to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18501
  end
end
