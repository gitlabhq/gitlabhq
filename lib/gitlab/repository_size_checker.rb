# frozen_string_literal: true

module Gitlab
  # Centralized class for repository size related calculations.
  class RepositorySizeChecker
    attr_reader :limit

    # @param current_size_proc [Proc] returns repository size in bytes
    def initialize(current_size_proc:, limit:, namespace:, enabled: true)
      @current_size_proc = current_size_proc
      @limit = limit
      @namespace = namespace
      @enabled = enabled && limit != 0
    end

    # @return [Integer] bytes
    def current_size
      @current_size ||= @current_size_proc.call
    end

    def enabled?
      @enabled
    end

    def above_size_limit?
      return false unless enabled?

      current_size > limit
    end

    # @param change_size [int] in bytes
    def changes_will_exceed_size_limit?(change_size)
      return false unless enabled?

      above_size_limit? || exceeded_size(change_size) > 0
    end

    # @param change_size [int] in bytes
    def exceeded_size(change_size = 0)
      size = current_size + change_size - limit

      [size, 0].max
    end

    def error_message
      @error_message_object ||= ::Gitlab::RepositorySizeErrorMessage.new(self)
    end

    def additional_repo_storage_available?
      false
    end

    private

    attr_reader :namespace
  end
end

Gitlab::RepositorySizeChecker.prepend_mod_with('Gitlab::RepositorySizeChecker')
