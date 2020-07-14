# frozen_string_literal: true

class AddDefaultValueStreamToGroupsWithGroupStages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Group < ActiveRecord::Base
    def self.find_sti_class(typename)
      if typename == 'Group'
        Group
      else
        super
      end
    end
    self.table_name = 'namespaces'
    has_many :group_value_streams
    has_many :group_stages
  end

  class GroupValueStream < ActiveRecord::Base
    self.table_name = 'analytics_cycle_analytics_group_value_streams'
    has_many :group_stages
    belongs_to :group
  end

  class GroupStage < ActiveRecord::Base
    self.table_name = 'analytics_cycle_analytics_group_stages'
    belongs_to :group_value_stream
  end

  def up
    Group.where(type: 'Group').joins(:group_stages).distinct.find_each do |group|
      Group.transaction do
        group_value_stream = group.group_value_streams.first_or_create!(name: 'default')
        group.group_stages.update_all(group_value_stream_id: group_value_stream.id)
      end
    end

    change_column_null :analytics_cycle_analytics_group_stages, :group_value_stream_id, false
  end

  def down
    change_column_null :analytics_cycle_analytics_group_stages, :group_value_stream_id, true

    GroupValueStream.where(name: 'default').includes(:group_stages).find_each do |value_stream|
      GroupValueStream.transaction do
        value_stream.group_stages.update_all(group_value_stream_id: nil)
        value_stream.destroy!
      end
    end
  end
end
