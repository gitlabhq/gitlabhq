module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Value < Lexeme::Base
            def self.type
              :value
            end
          end
        end
      end
    end
  end
end
