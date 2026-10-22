# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module ConditionalExposureHelpers
        extend ActiveSupport::Concern

        class_methods do
          def expose_field(field_name, **opts, &block)
            guarded_opts = options_with_guards(opts, build_request_guard(:fields, field_name, **opts))

            # rubocop:disable API/EntityFieldType -- helper method wraps expose to add guards
            expose(field_name, **guarded_opts, &block)
            # rubocop:enable API/EntityFieldType
          end

          # `source:` is the model widget backing the feature and defaults to the feature name: the exposure is
          # skipped unless the work item has that widget, and the block receives the widget object instead of
          # the work item. Pass `source: nil` for a feature with no backing widget.
          def expose_feature(feature_name, source: feature_name, **opts, &block)
            resolved_source = ensure_source_name(feature_name, source)

            guarded_opts = options_with_guards(opts,
              build_request_guard(:requested_features, feature_name, **opts),
              resolved_source ? build_source_guard(feature_name, resolved_source) : nil
            )

            block = source_block(block, resolved_source, feature_name) if resolved_source

            # rubocop:disable API/EntityFieldType -- helper method wraps expose to add guards
            expose(feature_name, **guarded_opts, &block)
            # rubocop:enable API/EntityFieldType
          end

          def requested?(requested_values, name)
            return false if requested_values.nil?

            Array(requested_values).any? { |value| value.to_s == name.to_s }
          end

          private

          def build_request_guard(filter_key, field_name, **opts)
            entity = self
            request_key = opts[:as] || field_name

            ->(_obj, options) { entity.requested?(options[filter_key], request_key) }
          end

          def options_with_guards(opts, *guards)
            opts = opts.dup
            combined_guards = Array(opts.delete(:if)) + guards.compact
            normalized = combined_guards.compact.map { |guard| normalize_guard(guard) }

            if normalized.one?
              opts[:if] = normalized.first
            elsif normalized.any?
              opts[:if] = ->(obj, options) { normalized.all? { |guard| guard.call(obj, options) } }
            end

            opts
          end

          def normalize_guard(guard)
            return guard if guard.respond_to?(:call)

            case guard
            when Symbol
              ->(_obj, options) { options[guard] }
            else
              raise ArgumentError, "Unsupported condition #{guard.inspect}"
            end
          end

          def ensure_source_name(feature_name, source)
            return if source.nil?

            unless source.is_a?(Symbol)
              raise ArgumentError, "Unsupported :source option #{source.inspect} for feature #{feature_name}"
            end

            unless ::WorkItems::TypesFramework::SystemDefined::WidgetDefinition.widget_types.include?(source.to_s)
              raise ArgumentError, "Unknown widget #{source.inspect} for feature #{feature_name}, " \
                "pass source: nil for a feature without a backing widget"
            end

            source
          end

          def build_source_guard(feature_name, source)
            ->(obj, _options) do
              unless obj.respond_to?(:has_widget?)
                raise ArgumentError, "Feature #{feature_name} requires entity object to respond to :has_widget?"
              end

              obj.has_widget?(source)
            end
          end

          def source_block(block, source, feature_name)
            original_block = block || ->(feature, _) { feature }

            ->(obj, options) do
              unless obj.respond_to?(:get_widget)
                raise ArgumentError, "Feature #{feature_name} requires entity object to respond to :get_widget"
              end

              feature = obj.get_widget(source)
              next unless feature

              original_block.arity <= 1 ? original_block.call(feature) : original_block.call(feature, options)
            end
          end
        end
      end
    end
  end
end
