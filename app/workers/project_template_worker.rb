class ProjectTemplateWorker
  include Sidekiq::Worker

  def perform(project_template_id, delete)
    project_template = ProjectTemplate.find_by_id(project_template_id)

    if project_template.nil?
      Gitlab::AppLogger.error("ProjectTemplateWorker: Could not find ProjectTemplate with id = #{project_template_id}")
      return false
    else
      if delete == false
        ProjectTemplateUnzipService.new.execute(project_template_id)
      else
        ProjectTemplateDeleteService.new.execute(project_template.id)
      end
    end
  end
end
