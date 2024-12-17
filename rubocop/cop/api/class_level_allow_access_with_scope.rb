# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      class ClassLevelAllowAccessWithScope < RuboCop::Cop::Base
        include CodeReuseHelpers

        # This cop checks that `allow_access_with_scope` is called only at the class level.
        # This is because `allow_access_with_scope` aggregates scopes for each call in a class.
        # Calling `allow_access_with_scope` within a `namespace` or an alias method such as
        # `resource`, `resources`, `segment` or `group` may mislead developers to think the scope
        # would be only allowed within given namespace which is not the case.
        #
        # @example
        #
        # # bad
        # class MyClass < ::API::Base
        #   include APIGuard
        #   namespace 'my_namespace' do
        #     resource :my_resource do
        #       allow_access_with_scope :ai_workflows
        #
        # # good
        # class MyClass < ::API::Base
        #   include APIGuard
        #   allow_access_with_scope :ai_workflows
        #
        MSG = '`allow_access_with_scope` should only be called on class-level and not within a namespace.'

        # In Grape::DSL::Routing::ClassMethods
        # group, segment, resource, and resources are all aliased to namespace
        BANNED_BLOCKS = %i[group namespace resource resources segment].freeze

        RESTRICT_ON_SEND = %i[allow_access_with_scope].freeze
        def on_send(node)
          return unless namespace?(node)

          add_offense(node)
        end

        private

        def namespace?(node)
          node.each_ancestor(:block).any? do |block_node|
            BANNED_BLOCKS.include?(block_node.method_name)
          end
        end
      end
    end
  end
end
