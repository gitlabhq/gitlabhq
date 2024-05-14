# frozen_string_literal: true

class UpdatePypiMetadataKeywordsCheckConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_text_limit(:packages_pypi_metadata, :keywords, 1024,
      constraint_name: check_constraint_name(:packages_pypi_metadata, :keywords, 'max_length_1KiB'))
    remove_text_limit(:packages_pypi_metadata, :keywords, constraint_name: 'check_02be2c39af')
  end

  def down
    # no-op: Danger of failing if there are records with length(keywords) > 255
  end
end
