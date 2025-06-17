# frozen_string_literal: true

module Gitlab
  module Database
    module Type
      # Extends Rails' ActiveRecord::Type::Json data type to remove JSON
      # encooded nullbytes `\u0000` to prevent PostgreSQL errors like
      # `PG::UntranslatableCharacter: ERROR: unsupported Unicode escape
      # sequence`.
      #
      # Example:
      #
      #   class SomeModel < ApplicationRecord
      #     # some_model.a_field is of type `jsonb`
      #     attribute :a_field, Gitlab::Database::Type::JsonPgSafe.new
      #   end
      class JsonPgSafe < ActiveRecord::Type::Json
        def initialize(replace_with: '')
          super()

          @replace_with = replace_with
        end

        def serialize(value)
          # Replace unicode null character(\u0000) that isn't escaped (not preceded by odd number of backslashes)
          super&.gsub(/(?<!\\)(?:\\\\)*\\u0000/, @replace_with)
        end
      end
    end
  end
end
