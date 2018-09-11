# frozen_string_literal: true

module Gitlab
  module Ci
    module External
      module File
        class Base
          YAML_WHITELIST_EXTENSION = /(yml|yaml)$/i.freeze

          def initialize(location, opts = {})
            @location = location
          end

          def valid?
            location.match(YAML_WHITELIST_EXTENSION) && content
          end

          def content
            raise NotImplementedError, 'content must be implemented and return a string or nil'
          end

          def error_message
            raise NotImplementedError, 'error_message must be implemented and return a string'
          end
        end
      end
    end
  end
end
