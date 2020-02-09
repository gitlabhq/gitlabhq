# frozen_string_literal: true

module API
  module Entities
    class MRNote < Grape::Entity
      expose :note
      expose :author, using: Entities::UserBasic
    end
  end
end
