# frozen_string_literal: true

module DependencyProxy
  module Expireable
    extend ActiveSupport::Concern

    UPDATE_BATCH_SIZE = 100

    private

    def expire_artifacts(collection)
      collection.each_batch(of: UPDATE_BATCH_SIZE) do |batch|
        batch.update_all(status: :pending_destruction)
      end
    end
  end
end
