# frozen_string_literal: true

class AddDingTalkTrackerData < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_on_dingtalk_tracker_data_corpid'

  def change
    create_table :dingtalk_tracker_data, comment: 'JiHu-specific table' do |t|
      t.references :integration, foreign_key: { on_delete: :cascade },
                                 type: :bigint, index: true, null: false, comment: 'JiHu-specific column'
      t.timestamps_with_timezone
      t.text :corpid, comment: 'JiHu-specific column', limit: 255
      t.index :corpid, where: "(corpid IS NOT NULL)", name: INDEX_NAME, comment: 'JiHu-specific index'
    end
  end
end
