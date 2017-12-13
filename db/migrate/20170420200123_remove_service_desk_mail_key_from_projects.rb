# rubocop:disable Migration/RemoveColumn
class RemoveServiceDeskMailKeyFromProjects < ActiveRecord::Migration
  DOWNTIME = false

  def change
    remove_column :projects, :service_desk_mail_key, :string
  end
end
