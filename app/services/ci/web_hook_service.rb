module Ci
  class WebHookService
    def build_end(build)
      execute_hooks(build.project, build_data(build))
    end

    def execute_hooks(project, data)
      project.web_hooks.each do |web_hook|
        async_execute_hook(web_hook, data)
      end
    end

    def async_execute_hook(hook, data)
      Sidekiq::Client.enqueue(Ci::WebHookWorker, hook.id, data)
    end

    def build_data(build)
      project = build.project
      data = {}
      data.merge!({
        build_id: build.id,
        build_name: build.name,
        build_status: build.status,
        build_started_at: build.started_at,
        build_finished_at: build.finished_at,
        project_id: project.id,
        project_name: project.name,
        gitlab_url: project.gitlab_url,
        ref: build.ref,
        sha: build.sha,
        before_sha: build.before_sha,
        push_data: build.commit.push_data
      })
    end
  end
end
