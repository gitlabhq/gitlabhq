module Ci
  class WebHookWorker
    include Sidekiq::Worker

    def perform(hook_id, data)
      Ci::WebHook.find(hook_id).execute data
    end
  end
end
