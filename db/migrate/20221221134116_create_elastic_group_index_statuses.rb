# frozen_string_literal: true

class CreateElasticGroupIndexStatuses < Gitlab::Database::Migration[2.1]
  def change
    create_table :elastic_group_index_statuses, id: false do |t|
      t.references :namespace,
                   primary_key: true,
                   foreign_key: { on_delete: :cascade },
                   index: false,
                   default: nil

      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :wiki_indexed_at

      t.binary :last_wiki_commit
    end
  end
end
