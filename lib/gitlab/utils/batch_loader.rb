# frozen_string_literal: true

module Gitlab
  module Utils
    module BatchLoader
      # Clears batched items under the specified batch key
      # https://github.com/exAspArk/batch-loader#batch-key
      def self.clear_key(batch_key)
        return if ::BatchLoader::Executor.current.nil?

        items_to_clear = ::BatchLoader::Executor.current.items_by_block.select do |k, v|
          # The Hash key here is [source_location, batch_key], so we just check k[1]
          k[1] == batch_key
        end

        items_to_clear.each do |k, v|
          ::BatchLoader::Executor.current.items_by_block.delete(k)
          ::BatchLoader::Executor.current.loaded_values_by_block.delete(k)
        end
      end
    end
  end
end
