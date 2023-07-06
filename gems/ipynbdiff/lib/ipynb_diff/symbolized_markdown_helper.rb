# frozen_string_literal: true

module IpynbDiff
  # Helper functions
  module SymbolizedMarkdownHelper
    def ___(symbol = nil, content = '')
      { symbol: symbol, content: content }
    end

    def symbolize_array(symbol, content)
      if content.is_a?(Array)
        content.map.with_index { |l, idx| ___(symbol / idx, yield(l)) }
      else
        content.split("\n").map { |c| ___(symbol, c) }
      end
    end
  end

  # Simple wrapper for a string
  class JsonSymbol < String
    def /(other)
      JsonSymbol.new((other.is_a?(Array) ? [self, *other] : [self, other]).join('.'))
    end
  end
end
