module Gitlab
  module Gfm
    module Ast
      module Syntax
        ##
        # Text description
        #
        class Text < Node
          def to_s
            @text
          end

          def self.allowed
            []
          end

          def self.pattern
            /(?<value>.+)/m
          end
        end
      end
    end
  end
end
