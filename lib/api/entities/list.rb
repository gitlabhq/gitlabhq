# frozen_string_literal: true

module API
  module Entities
    class List < Grape::Entity
      expose :id
      expose :label, using: Entities::LabelBasic
      expose :position
    end
  end
end

API::Entities::List.prepend_if_ee('EE::API::Entities::List')
