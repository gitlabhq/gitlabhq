module Gitlab
  module Diff
    module Formatters
      class BaseFormatter
        def initialize
        end

        def key
          raise NotImplementedError
        end

        def to_h
          raise NotImplementedError
        end
      end
    end
  end
end
