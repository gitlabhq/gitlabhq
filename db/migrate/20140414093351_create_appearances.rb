class CreateAppearances < ActiveRecord::Migration
  def change
    # GitLab CE may already have created this table, so to preserve
    # the upgrade path from CE -> EE we only create this if necessary.
    unless table_exists?(:appearances)
      create_table :appearances do |t|
        t.string :title
        t.text :description
        t.string :logo
        t.integer :updated_by

        t.timestamps
      end
    end
  end
end
