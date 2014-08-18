module Projects
  class RemoveWiki < Projects::Base
    def perform
      project = context[:project]

      context[:remove_wiki_job_id] = GitlabShellWorker.perform_async(
        :remove_repository,
        project.path_with_namespace + ".wiki"
      )
    end

    def rollback
      stop_async_job('gitlab_shell', context[:remove_repo_job_id])

      context.delete(:remove_wiki_job_id)
    end
  end
end
