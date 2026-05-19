# frozen_string_literal: true

module API
  module Entities
    class MRNote < Grape::Entity
      expose :note, documentation: { type: 'String', example: 'LGTM!' }
      expose :author, using: ::API::Entities::UserBasic
    end
  end
end
