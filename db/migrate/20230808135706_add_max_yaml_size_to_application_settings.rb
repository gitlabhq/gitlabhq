# frozen_string_literal: true

class AddMaxYamlSizeToApplicationSettings < Gitlab::Database::Migration[2.1]
  # Migration that is running immidiately after this migration is
  # UpdateCiMaxTotalYamlSizeBytesDefaultValue which will update the limit value
  # to whatever was set by the self-hosted customer.

  DEFAULT = 1.megabyte * 150 # max_yaml_size_bytes * ci_max_includes

  def change
    add_column :application_settings, :ci_max_total_yaml_size_bytes, :integer, default: DEFAULT, null: false
  end
end
