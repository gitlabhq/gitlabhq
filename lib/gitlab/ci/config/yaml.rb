# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class << self
          def load!(content, project: nil)
            Loader.new(content, project: project).to_result.then do |result|
              ##
              # raise an error for backwards compatibility
              #
              raise result.error unless result.valid?

              result.content
            end
          end

          def load_result!(content, project: nil)
            Loader.new(content, project: project).to_result
          end
        end
      end
    end
  end
end
