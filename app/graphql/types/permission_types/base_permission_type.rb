# frozen_string_literal: true

module Types
  module PermissionTypes
    class BasePermissionType < BaseObject
      extend Gitlab::Allowable

      RESOLVING_KEYWORDS = [:resolver, :method, :hash_key, :function].to_set.freeze

      def self.abilities(*abilities)
        abilities.each { |ability| ability_field(ability) }
      end

      def self.ability_field(ability, **kword_args, &block)
        define_field_resolver_method(ability) unless resolving_keywords?(kword_args)

        permission_field(ability, **kword_args, &block)
      end

      def self.permission_field(name, **kword_args, &block)
        kword_args = kword_args.reverse_merge(
          name: name,
          type: GraphQL::Types::Boolean,
          description: "If `true`, the user can perform `#{name}` on this resource",
          null: false)

        field(**kword_args, &block) # rubocop:disable Graphql/Descriptions
      end

      def self.define_field_resolver_method(ability)
        unless respond_to?(ability)
          define_method ability.to_sym do |*args|
            Ability.allowed?(context[:current_user], ability, object, **args.to_h)
          end
        end
      end

      def self.resolving_keywords?(arguments)
        RESOLVING_KEYWORDS.intersect?(arguments.keys.to_set)
      end
      private_class_method :resolving_keywords?
    end
  end
end
