# frozen_string_literal: true

module RuboCop
  module NodePatternHelper
    # Returns a nested `(const ...)` node pattern for a full qualified +name+.
    #
    # @examples
    #   const_pattern 'Foo::Bar' # => (const (const {nil? cbase} :Foo) :Bar)
    #   const_pattern 'Foo::Bar', parent: ':Baz' # => (const (const :Baz :Foo) :Bar)
    def const_pattern(name, parent: '{nil? cbase}')
      name.split('::').inject(parent) { |memo, name_part| "(const #{memo} :#{name_part})" }
    end
  end
end
