# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Flags direct usage of WorkItems::Type and
      # WorkItems::TypesFramework::SystemDefined::Type.
      #
      # These models should not be used directly. Instead, use
      # WorkItems::TypesFramework::Provider which is the single source
      # of truth for fetching work item types.
      #
      # @example Bad - Using WorkItems::Type directly
      #   # bad
      #   WorkItems::Type.default_by_type(:issue)
      #   ::WorkItems::Type.base_types
      #   WorkItems::TypesFramework::SystemDefined::Type.all
      #
      # @example Good - Using the Provider
      #   # good
      #   WorkItems::TypesFramework::Provider.new(namespace).find_by_base_type(:issue)
      #   WorkItems::TypesFramework::Provider.unfiltered_base_types
      #   WorkItems::TypesFramework::Provider.new(namespace).all
      class AvoidDirectWorkItemTypeUsage < RuboCop::Cop::Base
        MSG = 'Avoid using `WorkItems::Type` or `WorkItems::TypesFramework::SystemDefined::Type` directly. ' \
          'Use `WorkItems::TypesFramework::Provider` instead. ' \
          'See https://docs.gitlab.com/development/work_items.md'

        # @!method work_item_type_call?(node)
        def_node_matcher :work_item_type_call?, <<~PATTERN
          (send
            {
              (const (const {nil? (cbase)} :WorkItems) :Type)
              (const
                (const
                  (const
                    (const {nil? (cbase)} :WorkItems) :TypesFramework)
                  :SystemDefined)
                :Type)
            }
            _ ...)
        PATTERN

        def on_send(node)
          return unless work_item_type_call?(node)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
