# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module Storage
      extend self

      delegate :active?, to: ::Gitlab::SafeRequestStore
      delegate :[], :[]=, to: :storage

      def clear!
        storage.clear
      end

      private

      def storage
        ::Gitlab::SafeRequestStore.fetch(:instrumentation) { {} }
      end
    end
  end
end
