module Gitlab
  module Ci
    module Pipeline
      module Expression
        ExpressionError = Class.new(StandardError)
        RuntimeError = Class.new(ExpressionError)
      end
    end
  end
end
