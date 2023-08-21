# frozen_string_literal: true

# Renamed from AddInternalToNotes to AddInternalToNotesRenamed to avoid collision with an Elasticsearch migration  from
# the same name. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129012
class AddInternalToNotesRenamed < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column(:notes, :internal, :boolean, default: false, null: false)
  end
end
