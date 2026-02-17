# frozen_string_literal: true

class AddCheckConstraintConanPackageRevisionsRevisionLength < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  def up
    add_check_constraint(
      :packages_conan_package_revisions,
      'octet_length(revision) <= 20',
      'check_revision_length',
      validate: false
    )
  end

  def down
    remove_check_constraint(
      :packages_conan_package_revisions,
      'check_revision_length'
    )
  end
end
