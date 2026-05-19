# frozen_string_literal: true

class RemoveDefaultTimestampsFromServiceDeskSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    change_column_default :service_desk_settings, :created_at, from: -> { 'NOW()' }, to: nil
    change_column_default :service_desk_settings, :updated_at, from: -> { 'NOW()' }, to: nil
  end
end
