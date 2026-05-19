# frozen_string_literal: true

module API
  module Entities
    class List < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :label, using: ::API::Entities::LabelBasic
      expose :position, documentation: { type: 'Integer', example: 1 }
    end
  end
end

API::Entities::List.prepend_mod_with('API::Entities::List')
