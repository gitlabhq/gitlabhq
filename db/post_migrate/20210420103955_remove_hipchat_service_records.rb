# frozen_string_literal: true

class RemoveHipchatServiceRecords < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  class Service < ActiveRecord::Base
    include EachBatch

    self.table_name = 'services'
  end

  def up
    Service.each_batch(of: 100_000, column: :id) do |relation|
      relation.delete_by(type: 'HipchatService')
    end
  end

  def down
    # no-op
  end
end
