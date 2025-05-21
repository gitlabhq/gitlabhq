# frozen_string_literal: true

class AddNotNullToForkNetworksOrganizationId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '18.0'

  def up
    # no-op due to https://gitlab.com/gitlab-org/gitlab/-/issues/543167#note_2512131075
  end

  def down
    # no-op due to https://gitlab.com/gitlab-org/gitlab/-/issues/543167#note_2512131075
  end
end
