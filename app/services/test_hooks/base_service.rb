# frozen_string_literal: true

module TestHooks
  class BaseService
    include BaseServiceUtility

    attr_accessor :hook, :current_user, :trigger

    def initialize(hook, current_user, trigger)
      @hook = hook
      @current_user = current_user
      @trigger = trigger
    end

    def execute
      trigger_key = hook.class.triggers.key(trigger.to_sym)

      return error('Testing not available for this hook') if trigger_key.nil? || data.blank?

      return error(data[:error]) if data[:error].present?

      hook.execute(data, trigger_key, force: true)
    rescue ArgumentError => e
      error(e.message)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end
  end
end
