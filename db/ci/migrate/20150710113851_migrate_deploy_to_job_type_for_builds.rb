class MigrateDeployToJobTypeForBuilds < ActiveRecord::Migration
  def up
    execute("UPDATE builds SET job_type='test' WHERE NOT deploy")
    execute("UPDATE builds SET job_type='deploy' WHERE deploy")
  end
end
