# frozen_string_literal: true

module Namespaces
  module TransferHelper
    include NamespaceHelper

    def show_transfer_banner?(namespace)
      return false unless namespace&.persisted?

      namespace.self_or_ancestors_transfer_scheduled? || namespace.self_or_ancestors_transfer_in_progress?
    end

    def transfer_banner_message(namespace)
      messages = {
        group: s_(
          'TransferGroup|This group is scheduled for transfer. ' \
            'Users with the Maintainer or Owner role will be notified when the transfer succeeds or fails.'
        ),
        project: s_(
          'TransferProject|This project is scheduled for transfer. ' \
            'Users with the Maintainer or Owner role will be notified when the transfer succeeds or fails.'
        )
      }

      message_for_namespace(namespace, messages)
    end
  end
end
