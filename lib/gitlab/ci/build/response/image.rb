module Gitlab
  module Ci
    module Build
      module Response
        class Image
          attr_reader :name

          def initialize(image)
            type = image.class
            @name = image if type == String
          end

          def valid?
            @name != nil
          end
        end
      end
    end
  end
end
