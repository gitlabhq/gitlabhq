# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::If < Rules::Rule::Clause
        def initialize(expression)
          @expression = expression
        end

        def satisfied_by?(pipeline, seed)
          variables = seed.scoped_variables_hash

          ::Gitlab::Ci::Pipeline::Expression::Statement.new(@expression, variables).truthful?
        end
      end
    end
  end
end
