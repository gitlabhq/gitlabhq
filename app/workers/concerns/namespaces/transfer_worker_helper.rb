# frozen_string_literal: true

module Namespaces
  module TransferWorkerHelper
    extend ActiveSupport::Concern

    private

    def cancel_stale_transfer_state(namespace, **log_params)
      return unless namespace.transfer_in_progress?

      Gitlab::AppLogger.warn(
        message: 'Cancelling stale transfer state',
        state: namespace.state,
        **log_params
      )
      namespace.cancel_transfer!
    end
  end
end
