class ProjectTemplateObserver < BaseObserver
  def after_save(project_template)
    # check state of template, because after creating the new template the service manipulates the model and saves it again
    if project_template.state == 0
      log_info("ProjectTemplateObserver: Project Template #{project_template.name} was created.")
      ProjectTemplateWorker.perform_async(project_template.id, false)
    end
  end
end
