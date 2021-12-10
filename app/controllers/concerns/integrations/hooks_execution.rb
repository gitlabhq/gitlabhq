# frozen_string_literal: true

module Integrations::HooksExecution
  extend ActiveSupport::Concern

  private

  def destroy_hook(hook)
    result = WebHooks::DestroyService.new(current_user).execute(hook)

    if result[:status] == :success
      flash[:notice] =
        if result[:async]
          _("%{hook_type} was scheduled for deletion") % { hook_type: hook.model_name.human }
        else
          _("%{hook_type} was deleted") % { hook_type: hook.model_name.human }
        end
    else
      flash[:alert] = result[:message]
    end
  end

  def set_hook_execution_notice(result)
    http_status = result[:http_status]
    message = result[:message]

    if http_status && http_status >= 200 && http_status < 400
      flash[:notice] = "Hook executed successfully: HTTP #{http_status}"
    elsif http_status
      flash[:alert] = "Hook executed successfully but returned HTTP #{http_status} #{message}"
    else
      flash[:alert] = "Hook execution failed: #{message}"
    end
  end
end
