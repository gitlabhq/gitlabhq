module Gitlab
  module Ci
    class Config
      module Node
        class Error
          def initialize(message, parent)
            @message = message
            @parent = parent
          end

          def key
            @parent.key
          end

          def to_s
            "#{key}: #{@message}"
          end

          def ==(other)
            other.to_s == to_s
          end
        end
      end
    end
  end
end
