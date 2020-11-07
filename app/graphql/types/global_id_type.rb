# frozen_string_literal: true

module GraphQLExtensions
  module ScalarExtensions
    # Allow ID to unify with GlobalID Types
    def ==(other)
      if name == 'ID' && other.is_a?(self.class) &&
          other.type_class.ancestors.include?(::Types::GlobalIDType)
        return true
      end

      super
    end
  end
end

::GraphQL::ScalarType.prepend(GraphQLExtensions::ScalarExtensions)

module Types
  class GlobalIDType < BaseScalar
    graphql_name 'GlobalID'
    description 'A global identifier'

    # @param value [GID]
    # @return [String]
    def self.coerce_result(value, _ctx)
      ::Gitlab::GlobalId.as_global_id(value).to_s
    end

    # @param value [String]
    # @return [GID]
    def self.coerce_input(value, _ctx)
      return if value.nil?

      gid = GlobalID.parse(value)
      raise GraphQL::CoercionError, "#{value.inspect} is not a valid Global ID" if gid.nil?
      raise GraphQL::CoercionError, "#{value.inspect} is not a Gitlab Global ID" unless gid.app == GlobalID.app

      gid
    end

    # Construct a restricted type, that can only be inhabited by an ID of
    # a given model class.
    def self.[](model_class)
      @id_types ||= {}

      @id_types[model_class] ||= Class.new(self) do
        graphql_name "#{model_class.name.gsub(/::/, '')}ID"
        description "Identifier of #{model_class.name}"

        self.define_singleton_method(:to_s) do
          graphql_name
        end

        self.define_singleton_method(:inspect) do
          graphql_name
        end

        self.define_singleton_method(:coerce_result) do |gid, ctx|
          global_id = ::Gitlab::GlobalId.as_global_id(gid, model_name: model_class.name)

          if suitable?(global_id)
            global_id.to_s
          else
            raise GraphQL::CoercionError, "Expected a #{model_class.name} ID, got #{global_id}"
          end
        end

        self.define_singleton_method(:suitable?) do |gid|
          gid&.model_class&.ancestors&.include?(model_class)
        end

        self.define_singleton_method(:coerce_input) do |string, ctx|
          gid = super(string, ctx)
          raise GraphQL::CoercionError, "#{string.inspect} does not represent an instance of #{model_class.name}" unless suitable?(gid)

          gid
        end
      end
    end
  end
end
