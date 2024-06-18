# frozen_string_literal: true

module WebHooks
  class CreateService
    include Services::ReturnServiceResponses

    def initialize(current_user)
      @current_user = current_user
    end

    def execute(hook_params, relation)
      hook = relation.new(hook_params)

      if hook.save
        after_create(hook)
      else
        return error("Invalid url given", 422) if hook.errors[:url].present?
        return error("Invalid branch filter given", 422) if hook.errors[:push_events_branch_filter].present?

        error(hook.errors.full_messages.to_sentence, 422)
      end
    end

    private

    def after_create(hook)
      success({ hook: hook, async: false })
    end

    attr_reader :current_user
  end
end

WebHooks::CreateService.prepend_mod_with('WebHooks::CreateService')
