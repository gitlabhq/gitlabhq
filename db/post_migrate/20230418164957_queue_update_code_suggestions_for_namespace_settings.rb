# frozen_string_literal: true

class QueueUpdateCodeSuggestionsForNamespaceSettings < Gitlab::Database::Migration[2.1]
  def up
    # no-op due to not running anywhere yet and business decision to revert the decision
    # see: https://gitlab.com/gitlab-org/gitlab/-/issues/408104
  end

  def down
    # no-op
  end
end
