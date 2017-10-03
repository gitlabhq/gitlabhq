class LfsCleanupWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    projects = Project.joins(:lfs_pointers)
                      .joins(:lfs_objects)
                      .uniq

    projects.select(:id).find_each do |project|
      LfsProjectCleanupWorker.perform_async(project.id)
    end
  end
end
