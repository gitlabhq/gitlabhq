# frozen_string_literal: true

class UpdateMaxYamlSizeBytesDefault < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  NEW_DEFAULT = 2.megabytes
  OLD_DEFAULT = 1.megabyte

  def change
    change_column_default('application_settings', 'max_yaml_size_bytes', from: OLD_DEFAULT, to: NEW_DEFAULT)
  end
end
