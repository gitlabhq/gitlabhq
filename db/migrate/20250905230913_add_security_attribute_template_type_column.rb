# frozen_string_literal: true

class AddSecurityAttributeTemplateTypeColumn < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :security_attributes, :template_type, :integer, null: true, limit: 2
  end
end
