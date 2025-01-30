# frozen_string_literal: true

module Gitlab
  module Database
    module Type
      class JsonbFloat < ActiveModel::Type::Value
        def cast(value)
          Float(value, exception: false) || value
        end
      end
    end
  end
end
