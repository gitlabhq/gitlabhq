module HooksExecution
  extend ActiveSupport::Concern

  private

  def flash_notice(status, message)
    if status == 204 && message == 'skipped'
      'Hook execution was skipped due to branch filtering settings'
    else
      "Hook executed successfully: HTTP #{status}"
    end
  end

  def set_hook_execution_notice(result)
    http_status = result[:http_status]
    message = result[:message]

    if http_status.between?(200, 399)
      flash[:notice] = flash_notice(http_status, message)
    else
      flash[:alert] = "Hook executed successfully but returned HTTP #{http_status} #{message}"
    end
  rescue
    flash[:alert] = "Hook execution failed: #{message}"
  end
end
