# frozen_string_literal: true

module WebHooks
  module HookExecutionNotice
    private

    def set_hook_execution_notice(result)
      http_status = result.payload[:http_status]
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
end
