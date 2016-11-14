module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a Regular Expression.
        #
        class Regexp < Entry
          include Validatable

          validations do
            validates :config, regexp: true
          end

          def value
            if @config.first == '/' && @config.last == '/'
              @config[1...-1]
            else
              @config
            end
          end
        end
      end
    end
  end
end
