# frozen_string_literal: true

class UpdateInvalidWebHooks < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  class WebHook < ActiveRecord::Base
    include EachBatch

    self.table_name = 'web_hooks'
  end

  def up
    WebHook.each_batch(of: 10_000, column: :id) do |relation|
      relation.where(type: 'ProjectHook')
              .where.not(project_id: nil)
              .where.not(group_id: nil)
              .update_all(group_id: nil)
    end
  end

  def down
    # no-op
  end
end
