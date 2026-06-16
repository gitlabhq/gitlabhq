# frozen_string_literal: true

class UpdateOauthConsentsStatusDefault < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  # Removes the column default so every insert must set status
  # explicitly. A DEFAULT 0 silently resolves to authorized,
  # which is not appropriate for a consent table.
  def up
    change_column_default :oauth_consents, :status, from: 0, to: nil
  end

  def down
    # no-op: restoring a default that silently resolves to
    # authorized would undermine the explicit-consent design.
  end
end
