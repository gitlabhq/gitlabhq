# frozen_string_literal: true

module Gitlab
  module ActionCable
    module InstrumentationCallback
      def self.install
        ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
      end

      def self.wrapper
        ->(_, inner) do
          ::Gitlab::InstrumentationHelper.init_instrumentation_data
          inner.call
        end
      end
    end
  end
end
