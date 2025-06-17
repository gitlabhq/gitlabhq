# frozen_string_literal: true

module ClickHouse
  module Client
    module Quoting
      class << self
        def quote(value)
          case value
          when String, Symbol then "'#{value.gsub('\\', '\&\&').gsub("'", "''")}'"
          when Array then "[#{value.map { |v| quote(v) }.join(',')}]"
          when nil then "NULL"
          else value
          end
        end
      end
    end
  end
end
