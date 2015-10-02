class AddShaAndRefToBuilds < ActiveRecord::Migration
  def change
    add_column :ci_builds, :tag, :boolean
    add_column :ci_builds, :ref, :string
    add_column :ci_builds, :push_data, :text
  end
end
