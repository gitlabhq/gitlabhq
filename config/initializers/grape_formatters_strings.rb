# Since 4.0 (https://github.com/ruby-grape/grape/commit/6fa8f59e0475f926682168ad4f0bbb2f72df96a3)
# Grape no longer returns strings for JSON/XML.
# it means if code of an endpoint returns a string for application/json request, Grape will additionaly convert
# result to a string.
# Blog post of creator about this change: http://code.dblock.org/2013/03/17/grape-040-released-w-stricter-json-format-support-more.html

# The recommended monkey-code patch from Grape's creator to revert things back:
module Grape
  module Formatter
    module Json
      class << self
        def call(object, _env)
          return object if !object || object.is_a?(String)
          return JSON.dump(object) if object.is_a?(Hash)
          return object.to_json if object.respond_to?(:to_json)

          ::Grape::Json.dump(object)
        end
      end
    end
  end
end
