# frozen_string_literal: true

module Gitlab
  module ActionCable
    # Worker threads skip the Rack and Sidekiq middleware that enable the query analyzers.
    module QueryAnalyzerCallbacks
      def self.install
        ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
      end

      def self.wrapper
        ->(_, inner) do
          ::Gitlab::Database::QueryAnalyzer.instance.within { inner.call }
        end
      end
    end
  end
end
