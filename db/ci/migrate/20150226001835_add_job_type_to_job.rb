class AddJobTypeToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :job_type, :string, default: 'parallel'
    add_column :jobs, :refs, :string
  end
end
