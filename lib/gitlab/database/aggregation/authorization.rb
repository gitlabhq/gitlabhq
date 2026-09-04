# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      # Part-level authorization for aggregation engines.
      #
      # Part definitions (metrics, dimensions, filters) may declare an
      # `authorize:` option: an ability Symbol checked via `Ability.allowed?`
      # against every resource in `context[:authorization_resources]`, or a
      # callable invoked once with `(user, resources)` that is responsible for
      # authorizing all resources itself. Ability symbols are converted to
      # callables at definition time, so `authorize` is always a callable when
      # present.
      #
      # Unauthorized metrics are dropped from the request (their fields render
      # as `null`), while unauthorized dimensions, filters, and sort orders
      # fail request validation. Engines without any `authorize:` declarations
      # are not affected.
      module Authorization
        extend ActiveSupport::Concern

        # Normalizes the `authorize:` option: an ability Symbol is converted
        # into the equivalent callable, anything else is returned as-is.
        def self.ability_check(authorize)
          return authorize unless authorize.is_a?(Symbol)

          ->(user, resources) { resources.all? { |resource| ::Ability.allowed?(user, authorize, resource) } }
        end

        class_methods do
          def parts_require_authorization?
            (metrics + dimensions + filters).any?(&:authorize)
          end
        end

        private

        # Returns the request with unauthorized metrics dropped.
        def authorized_request(request)
          return request unless self.class.parts_require_authorization?

          verify_authorization_context!

          definitions = self.class.metrics.index_by(&:identifier)
          metrics = request.metrics.select do |configuration|
            authorized_definition?(definitions[configuration[:identifier]])
          end

          return request if metrics.size == request.metrics.size

          Request.new(
            metrics: metrics,
            dimensions: request.dimensions,
            filters: request.filters,
            order: request.order
          )
        end

        # Adds validation errors for unauthorized dimensions, filters, and
        # sort orders.
        def validate_authorization!(plan)
          return unless self.class.parts_require_authorization?

          validate_dimensions_authorization(plan)
          validate_filters_authorization(plan)
          validate_order_authorization(plan)
        end

        def validate_dimensions_authorization(plan)
          plan.dimensions.each do |dimension|
            next if authorized_part?(dimension)

            add_authorization_error(
              s_("AggregationEngine|access to dimension '%{identifier}' is not authorized"), dimension.definition)
          end
        end

        def validate_filters_authorization(plan)
          plan.filters.each do |filter|
            next if authorized_part?(filter) && authorized_definition?(referenced_metric_definition(filter))

            add_authorization_error(
              s_("AggregationEngine|access to filter '%{identifier}' is not authorized"), filter.definition)
          end
        end

        # A sort order referencing a metric pruned by `authorized_request` has
        # no plan part anymore; resolve the definition directly to report it
        # as unauthorized rather than as an unknown identifier.
        def validate_order_authorization(plan)
          plan.order.each do |order|
            definition = order.definition || ordered_metric_definition(order)
            next if authorized_definition?(definition)

            add_authorization_error(
              s_("AggregationEngine|ordering by '%{identifier}' is not authorized"), definition)
          end
        end

        def verify_authorization_context!
          return if context[:current_user].present? && context[:authorization_resources].present?

          raise ArgumentError,
            "#{self.class.name} declares part-level authorization: " \
              "`current_user:` and `authorization_resources:` are required in the engine context"
        end

        def add_authorization_error(message, definition)
          errors.add(:base, format(message, identifier: definition.identifier))
        end

        # Metric filters must also be authorized for the metric they reference.
        def referenced_metric_definition(filter)
          return unless filter.definition.try(:metric?)

          self.class.metrics.find { |metric| metric.identifier == filter.definition.identifier }
        end

        def ordered_metric_definition(order)
          self.class.metrics.find { |metric| metric.identifier == order.configuration[:identifier] }
        end

        # Parts with an unresolved definition are reported by plan validation.
        def authorized_part?(part)
          part.definition.nil? || authorized_definition?(part.definition)
        end

        def authorized_definition?(definition)
          authorize = definition&.authorize

          !authorize || authorize.call(context[:current_user], context[:authorization_resources])
        end
      end
    end
  end
end
