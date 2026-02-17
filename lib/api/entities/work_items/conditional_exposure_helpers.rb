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

          def expose_feature(feature_name, widget_name: nil, **opts, &block)
            resolved_widget = ensure_widget_name(feature_name, widget_name)

            guarded_opts = options_with_guards(opts,
              build_request_guard(:requested_features, feature_name, **opts),
              resolved_widget ? build_widget_guard(feature_name, resolved_widget) : nil
            )

            block = widget_block(block, resolved_widget, feature_name) if resolved_widget

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

          def ensure_widget_name(feature_name, widget_name)
            return if widget_name.nil?

            unless widget_name.is_a?(Symbol)
              raise ArgumentError, "Unsupported :widget_name option #{widget_name.inspect} for feature #{feature_name}"
            end

            widget_name
          end

          def build_widget_guard(feature_name, widget_name)
            ->(obj, _options) do
              unless obj.respond_to?(:has_widget?)
                raise ArgumentError, "Feature #{feature_name} requires entity object to respond to :has_widget?"
              end

              obj.has_widget?(widget_name)
            end
          end

          def widget_block(block, widget_name, feature_name)
            original_block = block || ->(widget, _) { widget }

            ->(obj, options) do
              unless obj.respond_to?(:get_widget)
                raise ArgumentError, "Feature #{feature_name} requires entity object to respond to :get_widget"
              end

              widget = obj.get_widget(widget_name)
              next unless widget

              original_block.arity <= 1 ? original_block.call(widget) : original_block.call(widget, options)
            end
          end
        end
      end
    end
  end
end
