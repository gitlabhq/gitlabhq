# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        LoadError = Class.new(StandardError)

        class << self
          def load!(content, inputs = {}, variables = [])
            Loader.new(content, inputs: inputs, variables: variables).load.then do |result|
              raise result.error_class, result.error if !result.valid? && result.error_class.present?
              raise LoadError, result.error unless result.valid?

              result.content
            end
          end
        end
      end
    end
  end
end
