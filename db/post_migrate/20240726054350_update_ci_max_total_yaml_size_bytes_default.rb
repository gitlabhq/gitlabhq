# frozen_string_literal: true

class UpdateCiMaxTotalYamlSizeBytesDefault < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  OLD_DEFAULT_MAX_YAML_SIZE_BYTES = 1.megabytes
  NEW_DEFAULT_MAX_YAML_SIZE_BYTES = 2.megabytes
  DEFAULT_CI_MAX_INCLUDES = 150

  OLD_DEFAULT = OLD_DEFAULT_MAX_YAML_SIZE_BYTES * DEFAULT_CI_MAX_INCLUDES
  NEW_DEFAULT = NEW_DEFAULT_MAX_YAML_SIZE_BYTES * DEFAULT_CI_MAX_INCLUDES

  def change
    change_column_default('application_settings', 'ci_max_total_yaml_size_bytes', from: OLD_DEFAULT, to: NEW_DEFAULT)
  end
end
