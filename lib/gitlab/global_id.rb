# frozen_string_literal: true

module Gitlab
  module GlobalId
    CoerceError = Class.new(ArgumentError)

    def self.build(object = nil, model_name: nil, id: nil, params: nil)
      if object
        model_name ||= object.class.name
        id ||= object.id
      end

      ::URI::GID.build(app: GlobalID.app, model_name: model_name, model_id: id, params: params)
    end

    def self.as_global_id(value, model_name: nil)
      case value
      when GlobalID
        value
      when URI::GID
        GlobalID.new(value)
      when Integer, String
        raise CoerceError, "Cannot coerce #{value.class}" unless model_name.present?

        GlobalID.new(::Gitlab::GlobalId.build(model_name: model_name, id: value))
      else
        raise CoerceError, "Invalid ID. Cannot coerce instances of #{value.class}"
      end
    end
  end
end
