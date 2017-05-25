module HooksExecution
  extend ActiveSupport::Concern

  private

  def set_hook_execution_notice(status, message)
    if status && status >= 200 && status < 400
      flash[:notice] = "Hook executed successfully: HTTP #{status}"
    elsif status
      flash[:alert] = "Hook executed successfully but returned HTTP #{status} #{message}"
    else
      flash[:alert] = "Hook execution failed: #{message}"
    end
  end
end
