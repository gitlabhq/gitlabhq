# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        module Tags
          class Reference < Base
            MissingReferenceError = Class.new(Tags::TagError)

            def self.tag
              '!reference'
            end

            override :valid?
            def valid?
              data[:seq].is_a?(Array) &&
                !data[:seq].empty? &&
                data[:seq].all? { |identifier| identifier.is_a?(String) }
            end

            private

            def location
              data[:seq].to_a.map(&:to_sym)
            end

            override :_resolve
            def _resolve(resolver)
              object = resolver.config.dig(*location)
              value = resolver.deep_resolve(object)

              raise MissingReferenceError, missing_ref_error_message unless value

              value
            end

            def missing_ref_error_message
              "#{data[:tag]} #{data[:seq].inspect} could not be found"
            end
          end
        end
      end
    end
  end
end
