# frozen_string_literal: true

class AddCheckConstraintConanPackageReferencesReferenceLength < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  def up
    add_check_constraint(
      :packages_conan_package_references,
      'octet_length(reference) <= 20',
      'check_reference_length',
      validate: false
    )
  end

  def down
    remove_check_constraint(
      :packages_conan_package_references,
      'check_reference_length'
    )
  end
end
