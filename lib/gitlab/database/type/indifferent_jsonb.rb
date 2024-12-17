# frozen_string_literal: true

module Gitlab
  module Database
    module Type
      # Extends Rails' Jsonb data type to deserialize it into indifferent access Hash.
      #
      # Example:
      #
      #   class SomeModel < ApplicationRecord
      #     # some_model.a_field is of type `jsonb`
      #     attribute :a_field, ::Gitlab::Database::Type::IndifferentJsonb.new
      #   end
      class IndifferentJsonb < ::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb
        def type
          :ind_jsonb
        end

        def deserialize(value)
          data = super
          return unless data

          ::Gitlab::Utils.deep_indifferent_access(data)
        end
      end
    end
  end
end
