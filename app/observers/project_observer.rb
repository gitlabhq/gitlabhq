class ProjectObserver < BaseObserver
  def after_create(project)
    project.update_column(:last_activity_at, project.created_at)

    return true if project.forked?

    if project.import?
      RepositoryImportWorker.perform_in(5.seconds, project.id)
    else
      GitlabShellWorker.perform_async(
        :add_repository,
        project.path_with_namespace
      )

      log_info("#{project.owner.name} created a new project \"#{project.name_with_namespace}\"")
    end

    if project.wiki_enabled?
      begin
        # force the creation of a wiki,
        GollumWiki.new(project, project.owner).wiki
      rescue GollumWiki::CouldNotCreateWikiError => ex
        # Prevent project observer crash
        # if failed to create wiki
        nil
      end
    end
  end

  def after_update(project)
    project.send_move_instructions if project.namespace_id_changed?
    project.rename_repo if project.path_changed?
  end

  def before_destroy(project)
    project.repository.expire_cache unless project.empty_repo?
  end

  def after_destroy(project)
    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace
    )

    GitlabShellWorker.perform_async(
      :remove_repository,
      project.path_with_namespace + ".wiki"
    )

    project.satellite.destroy

    log_info("Project \"#{project.name}\" was removed")
  end
end
