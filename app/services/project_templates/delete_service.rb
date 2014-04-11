class ProjectTemplateDeleteService

  attr_accessor :project_template

  def execute(project_template_id)
    @project_template = ProjectTemplate.find_by_id(project_template_id)

    if !@project_template.nil?
      delete_template_files
    end
  end

  def delete_template_files
    begin
      FileUtils.rm_rf(@project_template.template_delete_path) if File.directory?(@project_template.template_delete_path)
      @project_template.destroy
    rescue Exception => e
      Gitlab::AppLogger.error("ProjectTemplateDeleteService: Could not delete template directory for #{@project_template.name} - #{@project_template.template_delete_path}")
      Gitlab::AppLogger.error(e)
    end
  end

end
