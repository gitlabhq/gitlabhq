# rubocop:disable Migration/UpdateLargeTable
class AddRepositoryStorageToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default(:projects, :repository_storage, :string, default: 'default')
  end

  def down
    remove_column(:projects, :repository_storage)
  end
end
