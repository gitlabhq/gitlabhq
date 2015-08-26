class CreateCommitsFromBuilds < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.integer :project_id
      t.string  :ref,        nil: false
      t.string  :sha,        nil: false
      t.string  :before_sha, nil: false
      t.text    :push_data,  nil: false

      t.timestamps
    end

    add_column :builds, :commit_id, :integer

    # Remove commit data from builds
    #remove_column :builds, :project_id, :integer
    #remove_column :builds, :ref,        :string
    #remove_column :builds, :sha,        :string
    #remove_column :builds, :before_sha, :string
    #remove_column :builds, :push_data,  :text
  end
end
