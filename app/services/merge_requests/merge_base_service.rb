# frozen_string_literal: true

module MergeRequests
  class MergeBaseService < MergeRequests::BaseService
    include Gitlab::Utils::StrongMemoize

    MergeError = Class.new(StandardError)

    attr_reader :merge_request

    # Overridden in EE.
    def hooks_validation_pass?(merge_request, validate_squash_message: false)
      true
    end

    # Overridden in EE.
    def hooks_validation_error(merge_request, validate_squash_message: false)
      # No-op
    end

    private

    # Overridden in EE.
    def check_size_limit
      # No-op
    end

    # Overridden in EE.
    def error_check!
      # No-op
    end

    def raise_error(message)
      raise MergeError, message
    end

    def handle_merge_error(*args)
      # No-op
    end
  end
end

MergeRequests::MergeBaseService.prepend_mod_with('MergeRequests::MergeBaseService')
