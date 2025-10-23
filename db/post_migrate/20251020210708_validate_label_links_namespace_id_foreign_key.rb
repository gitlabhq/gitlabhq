# frozen_string_literal: true

class ValidateLabelLinksNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    validate_foreign_key :label_links, :namespace_id
  end

  def down
    # no-op
  end
end
