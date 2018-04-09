# Remove this initializer when upgraded to Rails 5.0
unless Gitlab.rails5?
  module ActiveRecord
    class PredicateBuilder
      class ArrayHandler
        module TypeCasting
          def call(attribute, value)
            # This is necessary because by default ActiveRecord does not respect
            # custom type definitions (like our `ShaAttribute`) when providing an
            # array in `where`, like in `where(commit_sha: [sha1, sha2, sha3])`.
            model = attribute.relation&.engine
            type = model.user_provided_columns[attribute.name] if model
            value = value.map { |value| type.type_cast_for_database(value) } if type

            super(attribute, value)
          end
        end

        prepend TypeCasting
      end
    end
  end
end
