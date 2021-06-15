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
    description <<~DESC
      A global identifier.

      A global identifier represents an object uniquely across the application.
      An example of such an identifier is `"gid://gitlab/User/1"`.

      Global identifiers are encoded as strings.
    DESC

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
        model_name = model_class.name

        graphql_name model_name_to_graphql_name(model_name)
        description <<~MD.strip
          A `#{graphql_name}` is a global ID. It is encoded as a string.

          An example `#{graphql_name}` is: `"#{::Gitlab::GlobalId.build(model_name: model_name, id: 1)}"`.
          #{
            if deprecation = Gitlab::GlobalId::Deprecations.deprecation_by(model_name)
              'The older format `"' +
              ::Gitlab::GlobalId.build(model_name: deprecation.old_model_name, id: 1).to_s +
              '"` was deprecated in ' +  deprecation.milestone + '.'
            end}

        MD

        define_singleton_method(:to_s) do
          graphql_name
        end

        define_singleton_method(:inspect) do
          graphql_name
        end

        define_singleton_method(:as) do |new_name|
          if @renamed && graphql_name != new_name
            raise "Conflicting names for ID of #{model_name}: " \
                  "#{graphql_name} and #{new_name}"
          end

          @renamed = true
          graphql_name(new_name)
          self
        end

        define_singleton_method(:coerce_result) do |gid, ctx|
          global_id = ::Gitlab::GlobalId.as_global_id(gid, model_name: model_name)

          next global_id.to_s if suitable?(global_id)

          raise GraphQL::CoercionError, "Expected a #{model_name} ID, got #{global_id}"
        end

        define_singleton_method(:suitable?) do |gid|
          next false if gid.nil?

          gid.model_name.safe_constantize.present? &&
            gid.model_class.ancestors.include?(model_class)
        end

        define_singleton_method(:coerce_input) do |string, ctx|
          gid = super(string, ctx)
          next gid if suitable?(gid)

          raise GraphQL::CoercionError, "#{string.inspect} does not represent an instance of #{model_name}"
        end
      end
    end

    def self.model_name_to_graphql_name(model_name)
      "#{model_name.gsub(/::/, '')}ID"
    end
  end
end
