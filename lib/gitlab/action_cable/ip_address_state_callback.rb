# frozen_string_literal: true

module Gitlab
  module ActionCable
    module IpAddressStateCallback
      def self.install
        ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
      end

      def self.wrapper
        ->(_, inner) do
          ::Gitlab::IpAddressState.with(connection.request.ip) do # rubocop: disable CodeReuse/ActiveRecord -- not an ActiveRecord object
            inner.call
          end
        end
      end
    end
  end
end
