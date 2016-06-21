module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a Docker image.
        #
        class Image < Entry
          include Validatable

          validations do
            validates :config, type: String
          end

          def value
            @config
          end
        end
      end
    end
  end
end
