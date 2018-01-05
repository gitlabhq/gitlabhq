module MergeRequests
  class WorkingCopyBaseService < MergeRequests::BaseService
    attr_reader :merge_request

    def source_project
      @source_project ||= merge_request.source_project
    end

    def target_project
      @target_project ||= merge_request.target_project
    end

    def log_error(message, save_message_on_model: false)
      Gitlab::GitLogger.error("#{self.class.name} error (#{merge_request.to_reference(full: true)}): #{message}")

      merge_request.update(merge_error: message) if save_message_on_model
    end

    # Don't try to print expensive instance variables.
    def inspect
      "#<#{self.class} #{merge_request.to_reference(full: true)}>"
    end
  end
end
