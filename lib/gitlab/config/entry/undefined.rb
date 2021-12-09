# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # This class represents an undefined entry.
      #
      class Undefined < Node
        def initialize(*)
          super(nil)
        end

        def value
          nil
        end

        def valid?
          true
        end

        def errors
          []
        end

        def specified?
          false
        end

        def relevant?
          false
        end

        def type
          nil
        end

        def inspect
          "#<#{self.class.name}>"
        end
      end
    end
  end
end
