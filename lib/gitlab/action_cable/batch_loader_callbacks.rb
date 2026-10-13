# frozen_string_literal: true

module Gitlab
  module ActionCable
    module BatchLoaderCallbacks
      def self.install
        ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
      end

      def self.wrapper
        ->(_, inner) do
          inner.call
        ensure
          # Worker threads skip the Rack and Sidekiq middleware that reset BatchLoader,
          # so a thread would otherwise serve values batched by an earlier task.
          ::BatchLoader::Executor.clear_current if Feature.enabled?(:clear_action_cable_loader, :instance)
        end
      end
    end
  end
end
