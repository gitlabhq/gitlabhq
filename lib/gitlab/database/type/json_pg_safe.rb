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
        def serialize(value)
          super&.gsub('\u0000', '')
        end
      end
    end
  end
end
