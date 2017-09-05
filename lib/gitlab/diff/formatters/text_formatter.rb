module Gitlab
  module Diff
    module Formatters
      class TextFormatter < BaseFormatter
        def key
          raise NotImplementedError
        end
      end
    end
  end
end
