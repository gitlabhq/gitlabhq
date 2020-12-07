# frozen_string_literal: true

class RemoveOrphanServiceHooks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class WebHook < ActiveRecord::Base
    include EachBatch

    self.table_name = 'web_hooks'

    def self.service_hooks
      where(type: 'ServiceHook')
    end
  end

  class Service < ActiveRecord::Base
    self.table_name = 'services'
  end

  def up
    WebHook.service_hooks.where.not(service_id: Service.select(:id)).where.not(service_id: nil).each_batch do |relation|
      relation.delete_all
    end
  end

  def down
    # no-op
  end
end
