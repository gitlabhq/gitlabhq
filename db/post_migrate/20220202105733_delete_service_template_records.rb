# frozen_string_literal: true

class DeleteServiceTemplateRecords < Gitlab::Database::Migration[1.0]
  class Integration < ActiveRecord::Base
    # Disable single-table inheritance
    self.inheritance_column = :_type_disabled
  end

  def up
    Integration.where(template: true).delete_all
  end

  def down
    # no-op
  end
end
