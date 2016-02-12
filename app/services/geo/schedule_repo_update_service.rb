class ScheduleRepoUpdateService
  attr_reader :projects

  def initialize(projects)
    @projects = projects
  end

  def execute
    @projects.each do |project_id|
      # TODO: async repository fetch
    end
  end
end
