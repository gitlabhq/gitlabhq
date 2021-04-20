# frozen_string_literal: true

class RemoveRecordsWithoutGroupFromWebhooksTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class WebHook < ActiveRecord::Base
    include EachBatch

    self.table_name = 'web_hooks'
  end

  class Group < ActiveRecord::Base
    self.inheritance_column = :_type_disabled
    self.table_name = 'namespaces'
  end

  def up
    subquery = Group.select(1).where(Group.arel_table[:id].eq(WebHook.arel_table[:group_id]))

    WebHook.each_batch(of: 500, column: :id) do |relation|
      relation.where(type: 'GroupHook').where.not('EXISTS (?)', subquery).delete_all
    end
  end

  def down
    # no-op
  end
end
