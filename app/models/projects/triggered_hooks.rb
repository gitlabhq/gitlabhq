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
          next if @scope == :emoji_hooks && Feature.disabled?(:emoji_webhooks, hook.parent)
          next if @scope == :resource_access_token_hooks && Feature.disabled?(:access_tokens_webhooks, hook.parent)

          hook.async_execute(@data, @scope.to_s)
        end
      end
    end
  end
end
