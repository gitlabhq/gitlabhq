# frozen_string_literal: true

module IpynbDiff
  require 'oj'

  # Creates a map from a symbol to the line number it appears in a Json file
  #
  # Example:
  #
  # Input:
  #
  # 1. {
  # 2.   'obj1': [
  # 3.     {
  # 4.       'obj2': 5
  # 5.     },
  # 6.     3,
  # 7.     {
  # 8.       'obj3': {
  # 9.         'obj4': 'b'
  # 10.      }
  # 11.    }
  # 12.  ]
  # 13.}
  #
  # Output:
  #
  # Symbol                Line Number
  # .obj1              -> 2
  # .obj1.0            -> 3
  # .obj1.0            -> 3
  # .obj1.0.obj2       -> 4
  # .obj1.1            -> 6
  # .obj1.2            -> 7
  # .obj1.2.obj3       -> 8
  # .obj1.2.obj3.obj4  -> 9
  #
  class SymbolMap
    # rubocop:disable Lint/UnusedMethodArgument
    class << self
      def handler
        @handler ||= SymbolMap.new
      end

      def parser
        @parser ||= Oj::Parser.new(:saj).tap { |p| p.handler = handler }
      end

      def parse(notebook, *args)
        handler.reset
        parser.parse(notebook)
        handler.symbols
      end
    end

    attr_accessor :symbols

    def hash_start(key, line, column)
      add_symbol(key_or_index(key), line)
    end

    def hash_end(key, line, column)
      @current_path.pop
    end

    def array_start(key, line, column)
      @current_array_index << 0

      add_symbol(key, line)
    end

    def array_end(key, line, column)
      @current_path.pop
      @current_array_index.pop
    end

    def add_value(value, key, line, column)
      add_symbol(key_or_index(key), line)

      @current_path.pop
    end

    def add_symbol(symbol, line)
      @symbols[@current_path.append(symbol).join('.')] = line if symbol
    end

    def key_or_index(key)
      if key.nil? # value in an array
        if @current_path.empty?
          @current_path = ['']
          return
        end

        symbol = @current_array_index.last
        @current_array_index[-1] += 1
        symbol
      else
        key
      end
    end

    def reset
      @current_path = []
      @symbols = {}
      @current_array_index = []
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
