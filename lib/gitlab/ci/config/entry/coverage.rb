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
        end
      end
    end
  end
end
