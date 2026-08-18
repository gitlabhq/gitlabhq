# frozen_string_literal: true

class ScopeSecurityAttributeNameUniquenessToNotDeleted < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  # Scopes the (security_category_id, name) and (namespace_id, name) unique indexes to
  # WHERE deleted_at IS NULL so a soft-deleted name can be reused. Regular (not post-deploy)
  # migration: the swap only loosens uniqueness, so it must run before the matching relaxed
  # validation. Plain leading-column indexes are added first to keep the FK index
  # coverage the old full unique indexes provided. The now redundant categories partial
  # index on namespace_id is dropped.

  ATTRIBUTES_TABLE = :security_attributes
  CATEGORIES_TABLE = :security_categories

  ATTRIBUTES_FK_INDEX = 'index_security_attributes_on_security_category_id'
  ATTRIBUTES_UNIQUE_INDEX = 'index_security_attributes_on_category_name_not_deleted'
  ATTRIBUTES_OLD_UNIQUE_INDEX = 'index_security_attributes_security_category_name'

  CATEGORIES_FK_INDEX = 'index_security_categories_on_namespace_id'
  CATEGORIES_UNIQUE_INDEX = 'index_security_categories_on_namespace_name_not_deleted'
  CATEGORIES_OLD_UNIQUE_INDEX = 'index_security_categories_namespace_name'
  CATEGORIES_REDUNDANT_PARTIAL_INDEX = 'index_security_categories_on_namespace_id_where_not_deleted'

  def up
    add_concurrent_index ATTRIBUTES_TABLE, :security_category_id, name: ATTRIBUTES_FK_INDEX
    add_concurrent_index ATTRIBUTES_TABLE, [:security_category_id, :name],
      unique: true, where: 'deleted_at IS NULL', name: ATTRIBUTES_UNIQUE_INDEX
    remove_concurrent_index_by_name ATTRIBUTES_TABLE, ATTRIBUTES_OLD_UNIQUE_INDEX

    add_concurrent_index CATEGORIES_TABLE, :namespace_id, name: CATEGORIES_FK_INDEX
    add_concurrent_index CATEGORIES_TABLE, [:namespace_id, :name],
      unique: true, where: 'deleted_at IS NULL', name: CATEGORIES_UNIQUE_INDEX
    remove_concurrent_index_by_name CATEGORIES_TABLE, CATEGORIES_OLD_UNIQUE_INDEX
    remove_concurrent_index_by_name CATEGORIES_TABLE, CATEGORIES_REDUNDANT_PARTIAL_INDEX
  end

  def down
    # Recreating the full unique indexes will fail if a soft-deleted row already share a name!
    add_concurrent_index ATTRIBUTES_TABLE, [:security_category_id, :name],
      unique: true, name: ATTRIBUTES_OLD_UNIQUE_INDEX
    remove_concurrent_index_by_name ATTRIBUTES_TABLE, ATTRIBUTES_UNIQUE_INDEX
    remove_concurrent_index_by_name ATTRIBUTES_TABLE, ATTRIBUTES_FK_INDEX

    add_concurrent_index CATEGORIES_TABLE, :namespace_id,
      where: 'deleted_at IS NULL', name: CATEGORIES_REDUNDANT_PARTIAL_INDEX
    add_concurrent_index CATEGORIES_TABLE, [:namespace_id, :name],
      unique: true, name: CATEGORIES_OLD_UNIQUE_INDEX
    remove_concurrent_index_by_name CATEGORIES_TABLE, CATEGORIES_UNIQUE_INDEX
    remove_concurrent_index_by_name CATEGORIES_TABLE, CATEGORIES_FK_INDEX
  end
end
