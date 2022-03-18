# frozen_string_literal: true

module Gitlab
  module Database
    module Type
      class Color < ActiveModel::Type::Value
        def serialize(value)
          value.to_s if value
        end

        def serializable?(value)
          value.nil? || value.is_a?(::String) || value.is_a?(::Gitlab::Color)
        end

        def cast_value(value)
          ::Gitlab::Color.new(value.to_s)
        end
      end
    end
  end
end
