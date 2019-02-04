class AddRefAndTagToBuilds < ActiveRecord::Migration[4.2]
  def change
    add_column :ci_builds, :tag, :boolean
    add_column :ci_builds, :ref, :string
  end
end
