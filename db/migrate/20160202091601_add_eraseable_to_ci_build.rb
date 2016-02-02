class AddEraseableToCiBuild < ActiveRecord::Migration
  def change
    add_column :ci_builds, :erased, :boolean, default: false
    add_reference :ci_builds, :erased_by, references: :users, index: true
    add_foreign_key :ci_builds, :users, column: :erased_by_id
    add_column :ci_builds, :erased_at, :datetime
  end
end
