module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents Coverage settings.
        #
        class Coverage < Node
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
