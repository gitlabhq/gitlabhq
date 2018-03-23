module Gitlab
  module Ci
    module Build
      module Policy
        class Variables < Policy::Specification
          def initialize(expressions)
            @expressions = Array(expressions)
          end

          def satisfied_by?(pipeline, seed)
            variables = Gitlab::Ci::Variables::Collection
              .new(seed.to_resource.simple_variables)
              .to_hash

            statements = @expressions.map do |statement|
              ::Gitlab::Ci::Pipeline::Expression::Statement
                .new(statement, variables)
            end

            statements.any?(&:truthful?)
          end
        end
      end
    end
  end
end
