class AddErasableToCiBuild < ActiveRecord::Migration
  def change
    add_reference :ci_builds, :erased_by, references: :users, index: true
    add_column :ci_builds, :erased_at, :datetime
  end
end
