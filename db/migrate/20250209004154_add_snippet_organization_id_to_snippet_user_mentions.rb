# frozen_string_literal: true

class AddSnippetOrganizationIdToSnippetUserMentions < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :snippet_user_mentions, :snippet_organization_id, :bigint
  end
end
