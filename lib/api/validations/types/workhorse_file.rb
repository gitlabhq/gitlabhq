# frozen_string_literal: true

module API
  module Validations
    module Types
      class WorkhorseFile
        def self.parse(value)
          return if value.blank?
          raise "#{value.class} is not an UploadedFile type" unless parsed?(value)

          value
        end

        def self.parsed?(value)
          value.is_a?(::UploadedFile)
        end
      end
    end
  end
end
