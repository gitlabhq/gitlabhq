# frozen_string_literal: true

module Gitlab
  module GlobalId
    def self.build(object = nil, model_name: nil, id: nil, params: nil)
      if object
        model_name ||= object.class.name
        id ||= object.id
      end

      ::URI::GID.build(app: GlobalID.app, model_name: model_name, model_id: id, params: params)
    end
  end
end
