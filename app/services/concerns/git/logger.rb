# frozen_string_literal: true

module Git
  module Logger
    def log_error(message, save_message_on_model: false)
      Gitlab::GitLogger.error("#{self.class.name} error (#{merge_request.to_reference(full: true)}): #{message}")
      merge_request.update(merge_error: message) if save_message_on_model
    end
  end
end
