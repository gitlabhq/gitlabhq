# frozen_string_literal: true

module API
  module Validations
    module Types
      class WorkhorseFile < Virtus::Attribute
        def coerce(input)
          # Processing of multipart file objects
          # is already taken care of by Gitlab::Middleware::Multipart.
          # Nothing to do here.
          input
        end

        def value_coerced?(value)
          value.is_a?(::UploadedFile)
        end
      end
    end
  end
end
