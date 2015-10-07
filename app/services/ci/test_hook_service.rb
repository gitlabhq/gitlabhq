module Ci
  class TestHookService
    def execute(hook, current_user)
      Ci::WebHookService.new.build_end(hook.project.commits.last.last_build)
    end
  end
end
