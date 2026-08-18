# frozen_string_literal: true

module Namespaces
  module TransferWorkerHelper
    extend ActiveSupport::Concern

    include Namespaces::TransferLogging

    private

    def cancel_stale_transfer_state(namespace, **log_params)
      return unless namespace.transfer_in_progress?

      Gitlab::AppLogger.warn(
        build_transfer_log_payload(
          message: 'Cancelling stale transfer state',
          namespace: namespace,
          **log_params
        )
      )
      namespace.cancel_transfer!
    end

    def create_transfer_failure_todo(target, user, worker_name:, **log_params)
      TodoService.new.transfer_failed(target, user)
    rescue StandardError => e
      Gitlab::AppLogger.error(
        {
          message: "#{worker_name} failed to create transfer failure todo",
          Labkit::Fields::GL_USER_ID => user.id,
          Labkit::Fields::ERROR_MESSAGE => e.message
        }.merge(log_params)
      )
    end

    def resolve_transfer_failure_todo(target, user, worker_name:, **log_params)
      todo = Todo.pending_transfer_failed_for(user: user, target: target)
      return unless todo

      TodoService.new.resolve_todo(todo, user)
    rescue StandardError => e
      Gitlab::AppLogger.error(
        {
          message: "#{worker_name} failed to resolve transfer failure todo",
          Labkit::Fields::GL_USER_ID => user.id,
          Labkit::Fields::ERROR_MESSAGE => e.message
        }.merge(log_params)
      )
    end
  end
end
