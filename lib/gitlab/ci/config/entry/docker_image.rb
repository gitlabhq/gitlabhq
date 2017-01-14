module Gitlab
  module Ci
    class Config
      module Entry
        module DockerImage
          def hash?
            @config.is_a?(Hash)
          end

          def string?
            @config.is_a?(String)
          end

          def name
            value[:name]
          end

          def entrypoint
            value[:entrypoint]
          end

          def value
            return { name: @config } if string?
            return @config if hash?
            {}
          end
        end
      end
    end
  end
end
