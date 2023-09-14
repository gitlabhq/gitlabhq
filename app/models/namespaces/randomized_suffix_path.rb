# frozen_string_literal: true

module Namespaces
  class RandomizedSuffixPath
    MAX_TRIES = 4
    LEADING_ZEROS = /^0+/

    def initialize(path)
      @path = path
    end

    def call(new_count)
      @count = new_count.to_i
      to_s
    end

    def to_s
      "#{path}#{suffix}"
    end

    private

    attr_reader :count, :path

    def randomized_suffix
      Time.current.strftime('%L%M%V').sub(LEADING_ZEROS, '').to_i + offset
    end

    def offset
      count - MAX_TRIES - 1
    end

    def suffix
      return if count.nil?
      return randomized_suffix if count > MAX_TRIES
      return count if count > 0
    end
  end
end
