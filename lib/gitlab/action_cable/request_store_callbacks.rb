# frozen_string_literal: true

module Gitlab
  module ActionCable
    module RequestStoreCallbacks
      def self.install
        ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
      end

      def self.wrapper
        lambda do |_, inner|
          ::Gitlab::SafeRequestStore.ensure_request_store do
            inner.call
          end
        end
      end
    end
  end
end
