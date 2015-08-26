class MigrateJobs < ActiveRecord::Migration
  def up
    Project.find_each(batch_size: 100) do |project|
      job = project.jobs.create(commands: project.scripts)
      project.builds.order('id DESC').limit(10).update_all(job_id: job.id)
    end
  end

  def down
    Job.destroy_all
  end
end
