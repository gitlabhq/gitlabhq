# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::If < Rules::Rule::Clause
        def initialize(expression)
          @expression = expression
        end

        def satisfied_by?(_pipeline, context)
          ::Gitlab::Ci::Pipeline::Expression::Statement.new(
            @expression, context.variables_hash).truthful?
        end
      end
    end
  end
end
