module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a Docker image.
        #
        class Image < Node
          include Validatable

          validations do
            validates :config, type: String
          end
        end
      end
    end
  end
end
