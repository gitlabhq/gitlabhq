module Gitlab
  module Gfm
    module Ast
      module Syntax
        ##
        # Text description
        #
        class Text < Node
          def allowed
            []
          end

          def value
            @text
          end

          def to_s
            @text
          end

          def self.pattern
            /(?<value>.+)/m
          end
        end
      end
    end
  end
end
