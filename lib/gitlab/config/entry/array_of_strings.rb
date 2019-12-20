# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # Entry that represents a array of strings value.
      #
      class ArrayOfStrings < Node
        include Validatable

        validations do
          validates :config, array_of_strings: true
        end
      end
    end
  end
end
