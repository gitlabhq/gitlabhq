# frozen_string_literal: true

class AddIdxPkgsConanRecipeRevOnIdAndRevision < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = 'idx_pkgs_conan_recipe_rev_on_id_and_revision'

  def up
    add_concurrent_index(
      :packages_conan_recipe_revisions,
      [:id, :revision],
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:packages_conan_recipe_revisions, INDEX_NAME)
  end
end
