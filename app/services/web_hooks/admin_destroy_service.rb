# frozen_string_literal: true

module WebHooks
  # A variant of the destroy service that can only be used by an administrator
  # from a rake task.
  class AdminDestroyService < WebHooks::DestroyService
    def initialize(rake_task:)
      super(nil)
      @rake_task = rake_task
    end

    def authorized?(web_hook)
      @rake_task.present? # Not impossible to circumvent, but you need to provide something
    end

    def log_message(hook)
      "An administrator scheduled a deletion of logs for hook ID #{hook.id} from #{@rake_task.name}"
    end
  end
end
