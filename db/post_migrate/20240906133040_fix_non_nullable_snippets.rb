# frozen_string_literal: true

class FixNonNullableSnippets < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    return unless Gitlab.com?

    retry_count = 0
    begin
      model = define_batchable_model(:snippets)
      model.transaction do
        relation = model.where(type: 'ProjectSnippet').where.not(organization_id: nil)

        relation.select(:id).find_each do |snippet|
          snippet.update_column(:organization_id, nil)
        end
      end
    rescue ActiveRecord::QueryCanceled # rubocop:disable Database/RescueQueryCanceled -- to reuse a buffer cache to process stuck records
      retry_count += 1
      retry if retry_count < 5
    end
  end

  def down
    # no-op
  end
end
