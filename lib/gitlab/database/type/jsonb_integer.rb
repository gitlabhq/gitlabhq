# frozen_string_literal: true

module Gitlab
  module Database
    module Type
      class JsonbInteger < ActiveModel::Type::Value
        def cast(value)
          Integer(value, exception: false) || value
        end
      end
    end
  end
end
