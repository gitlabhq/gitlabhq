# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module DelegateCache
      def relation_delegate_class(klass)
        @relation_delegate_cache2[klass] || super # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def initialize_relation_delegate_cache_disable_joins
        @relation_delegate_cache2 = {} # rubocop:disable Gitlab/ModuleWithInstanceVariables

        [
          ::GemExtensions::ActiveRecord::DisableJoins::Relation
        ].each do |klass|
          delegate = Class.new(klass) do
            include ::ActiveRecord::Delegation::ClassSpecificRelation
          end
          include_relation_methods(delegate)
          mangled_name = klass.name.gsub("::", "_")
          const_set mangled_name, delegate
          private_constant mangled_name

          @relation_delegate_cache2[klass] = delegate # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end
      end

      def inherited(child_class)
        child_class.initialize_relation_delegate_cache_disable_joins
        super
      end
    end
  end
end
