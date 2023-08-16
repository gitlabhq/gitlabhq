# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        class Access
          attr_reader :content, :errors

          MAX_ACCESS_OBJECTS = 5
          MAX_ACCESS_BYTESIZE = 1024

          def initialize(access, ctx)
            @content = access
            @ctx = ctx
            @errors = []

            if objects.count <= 1 # rubocop:disable Style/IfUnlessModifier
              @errors.push('invalid interpolation access pattern')
            end

            if access.bytesize > MAX_ACCESS_BYTESIZE # rubocop:disable Style/IfUnlessModifier
              @errors.push('maximum interpolation expression size exceeded')
            end

            evaluate! if valid?
          end

          def valid?
            errors.none?
          end

          def objects
            @objects ||= @content.split('.', MAX_ACCESS_OBJECTS)
          end

          def value
            raise ArgumentError, 'access path invalid' unless valid?

            @value
          end

          private

          def evaluate!
            raise ArgumentError, 'access path invalid' unless valid?

            @value ||= objects.inject(@ctx) do |memo, value|
              key = value.to_sym

              break @errors.push("unknown interpolation key: `#{key}`") unless memo.key?(key)

              memo.fetch(key)
            end
          end
        end
      end
    end
  end
end
