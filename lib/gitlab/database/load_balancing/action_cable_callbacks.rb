# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      module ActionCableCallbacks
        def self.install
          ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
        end

        def self.wrapper
          ->(_, inner) do
            inner.call
          ensure
            ::Gitlab::Database::LoadBalancing.release_hosts
            ::Gitlab::Database::LoadBalancing::SessionMap.clear_session
          end
        end
      end
    end
  end
end
