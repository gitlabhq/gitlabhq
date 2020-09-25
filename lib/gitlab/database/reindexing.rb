# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      def self.perform(index_selector)
        Array.wrap(index_selector).each do |index|
          ConcurrentReindex.new(index).perform
        end
      end
    end
  end
end
