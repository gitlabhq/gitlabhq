class AddRefAndTagToBuilds < ActiveRecord::Migration
  def change
    add_column :ci_builds, :tag, :boolean
    add_column :ci_builds, :ref, :string
  end
end
