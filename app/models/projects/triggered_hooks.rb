# frozen_string_literal: true

module Projects
  class TriggeredHooks
    def initialize(scope, data)
      @scope = scope
      @data = data
      @relations = []
    end

    def add_hooks(relation)
      @relations << relation
      self
    end

    def execute
      # Assumes that the relations implement TriggerableHooks
      @relations.each do |hooks|
        hooks.hooks_for(@scope).select_active(@scope, @data).each do |hook|
          hook.async_execute(@data, @scope.to_s)
        end
      end
    end
  end
end
