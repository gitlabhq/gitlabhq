# frozen_string_literal: true

module Types
  module PermissionTypes
    class BasePermissionType < BaseObject
      extend Gitlab::Allowable

      RESOLVING_KEYWORDS = [:resolver, :method, :hash_key, :function].to_set.freeze

      def self.abilities(*abilities)
        abilities.each { |ability| ability_field(ability) }
      end

      def self.ability_field(ability, **kword_args)
        unless resolving_keywords?(kword_args)
          kword_args[:resolve] ||= -> (object, args, context) do
            can?(context[:current_user], ability, object, args.to_h)
          end
        end

        permission_field(ability, **kword_args)
      end

      def self.permission_field(name, **kword_args)
        kword_args = kword_args.reverse_merge(
          name: name,
          type: GraphQL::BOOLEAN_TYPE,
          description: "Indicates the user can perform `#{name}` on this resource",
          null: false)

        field(**kword_args) # rubocop:disable Graphql/Descriptions
      end

      def self.resolving_keywords?(arguments)
        RESOLVING_KEYWORDS.intersect?(arguments.keys.to_set)
      end
      private_class_method :resolving_keywords?
    end
  end
end
