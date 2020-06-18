# frozen_string_literal: true

module Uploads
  class Base
    BATCH_SIZE = 100

    attr_reader :logger

    def initialize(logger: nil)
      @logger = Gitlab::AppLogger
    end

    def delete_keys_async(keys_to_delete)
      keys_to_delete.each_slice(BATCH_SIZE) do |batch|
        DeleteStoredFilesWorker.perform_async(self.class, batch)
      end
    end
  end
end
