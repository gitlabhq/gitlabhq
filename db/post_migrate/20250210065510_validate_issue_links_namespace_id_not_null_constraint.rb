# frozen_string_literal: true

class ValidateIssueLinksNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :issue_links, :namespace_id
  end

  def down
    # no-op
  end
end
