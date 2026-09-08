# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Engine
        include ActiveModel::Validations
        include Authorization
        extend Dsl

        class << self
          def name
            to_s
          end

          def metrics_mapping
            raise NoMethodError
          end

          def filters_mapping
            raise NoMethodError
          end

          def dimensions_mapping
            raise NoMethodError
          end

          def build(&block)
            Class.new(self).tap { |klass| klass.class_eval(&block) }
          end
        end

        attr_reader :context

        def initialize(context:)
          @context = context
        end

        # @return [Gitlab::Database::Aggregation::AggregationResult]
        def execute(request)
          plan = authorized_request(request).to_query_plan(self)

          if plan_valid?(plan)
            ServiceResponse.success(payload: { data: execute_query_plan(plan) })
          else
            error_response
          end
        end

        def plan_valid?(plan)
          validate
          validate_authorization!(plan)

          if errors.empty?
            plan.validate
            errors.merge!(plan.errors)
          end

          errors.empty?
        end

        private

        def error_response
          ServiceResponse.error(payload: { errors: errors }, message: errors.full_messages.join(', '))
        end

        def execute_query_plan(_plan)
          raise NoMethodError
        end
      end
    end
  end
end
