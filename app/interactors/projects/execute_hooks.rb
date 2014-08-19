module Projects
  class ExecuteHooks < Projects::Base
    def setup
      context.fail!(message: "Invalid push data") if context[:push_data].blank?
      context.fail!(message: "Invalid hooks type") if context[:hooks_type].blank?
    end

    def perform
      project = context[:project]
      push_data = context[:push_data]
      hooks_type = context[:hooks_type]

      project.execute_hooks(push_data.dup, hooks_type)
    end

    def rollback
      # Nothing todo
    end
  end
end
