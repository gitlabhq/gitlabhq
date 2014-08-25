module Projects
  class ExecuteServices < Projects::Base
    def setup
      context.fail!(message: 'Invalid push data') if context[:push_data].blank?
    end

    def perform
      project = context[:project]
      push_data = context[:push_data]

      project.execute_services(push_data.dup)
    end

    def rollback
      # Nothing todo
    end
  end
end
