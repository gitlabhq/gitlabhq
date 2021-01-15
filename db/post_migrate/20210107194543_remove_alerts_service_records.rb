# frozen_string_literal: true

class RemoveAlertsServiceRecords < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class Service < ActiveRecord::Base
    self.table_name = 'services'
  end

  def up
    Service.delete_by(type: 'AlertsService')
  end

  def down
    # no-op
  end
end
