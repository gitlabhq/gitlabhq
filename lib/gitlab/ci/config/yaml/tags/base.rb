# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        module Tags
          class Base
            CircularReferenceError = Class.new(Tags::TagError)
            NotValidError = Class.new(Tags::TagError)

            extend ::Gitlab::Utils::Override

            attr_accessor :resolved_status, :resolved_value, :data

            def self.tag
              raise NotImplementedError
            end

            # Only one of the `seq`, `scalar`, `map` fields is available.
            def init_with(coder)
              @data = {
                tag: coder.tag,       # This is the custom YAML tag, like !reference or !flatten
                style: coder.style,
                seq: coder.seq,       # This holds Array data
                scalar: coder.scalar, # This holds data of basic types, like String.
                map: coder.map        # This holds Hash data.
              }
            end

            def valid?
              raise NotImplementedError
            end

            def resolve(resolver)
              raise NotValidError, validation_error_message unless valid?
              raise CircularReferenceError, circular_error_message if resolving?
              return resolved_value if resolved?

              self.resolved_status = :in_progress
              self.resolved_value = _resolve(resolver)
              self.resolved_status = :done
              resolved_value
            end

            private

            def _resolve(resolver)
              raise NotImplementedError
            end

            def resolved?
              resolved_status == :done
            end

            def resolving?
              resolved_status == :in_progress
            end

            def circular_error_message
              "#{data[:tag]} #{data[:seq].inspect} is part of a circular chain"
            end

            def validation_error_message
              "#{data[:tag]} #{(data[:scalar].presence || data[:map].presence || data[:seq]).inspect} is not valid"
            end
          end
        end
      end
    end
  end
end
