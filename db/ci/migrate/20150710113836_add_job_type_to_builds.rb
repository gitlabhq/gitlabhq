class AddJobTypeToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :job_type, :string
  end
end
