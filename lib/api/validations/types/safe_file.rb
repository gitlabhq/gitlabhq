# frozen_string_literal: true

# This module overrides the Grape type validator defined in
# https://github.com/ruby-grape/grape/blob/master/lib/grape/validations/types/file.rb
module API
  module Validations
    module Types
      class SafeFile < ::Grape::Validations::Types::File
        def value_coerced?(value)
          super && value[:tempfile].is_a?(Tempfile)
        end
      end
    end
  end
end
