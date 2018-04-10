module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Operator < Lexeme::Base
            def self.type
              :operator
            end
          end
        end
      end
    end
  end
end
