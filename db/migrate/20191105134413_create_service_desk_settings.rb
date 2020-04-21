# frozen_string_literal: true

class CreateServiceDeskSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :service_desk_settings, id: false do |t|
      t.references :project,
                   primary_key: true,
                   default: nil,
                   null: false,
                   index: false,
                   foreign_key: { on_delete: :cascade }

      t.string :issue_template_key, limit: 255
    end
  end
  # rubocop:enable Migration/PreventStrings
end
