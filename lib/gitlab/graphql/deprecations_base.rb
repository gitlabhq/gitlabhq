# frozen_string_literal: true

module Gitlab
  module Graphql
    # include DeprecationsBase at the end of the target module
    module DeprecationsBase
      NameDeprecation = Struct.new(:old_name, :new_name, :milestone, keyword_init: true)

      def self.included(klass)
        klass.extend(ClassMethods)

        klass.const_set(:OLD_GRAPHQL_NAME_MAP, klass::DEPRECATIONS.index_by do |d|
          klass.map_graphql_name(d.old_name)
        end.freeze)
        klass.const_set(:OLD_NAME_MAP, klass::DEPRECATIONS.index_by(&:old_name).freeze)
        klass.const_set(:NEW_NAME_MAP, klass::DEPRECATIONS.index_by(&:new_name).freeze)
      end

      module ClassMethods
        def deprecated?(old_name)
          self::OLD_NAME_MAP.key?(old_name)
        end

        def deprecation_for(old_name)
          self::OLD_NAME_MAP[old_name]
        end

        def deprecation_by(new_name)
          self::NEW_NAME_MAP[new_name]
        end

        # Returns the new `graphql_name` (Type#graphql_name) of a deprecated GID,
        # or the `graphql_name` argument given if no deprecation applies.
        def apply_to_graphql_name(graphql_name)
          return graphql_name unless deprecation = self::OLD_GRAPHQL_NAME_MAP[graphql_name]

          self.map_graphql_name(deprecation.new_name)
        end

        private

        def map_graphql_name(name)
          raise NotImplementedError, "Implement `#{__method__}` in #{self.name}"
        end
      end
    end
  end
end
