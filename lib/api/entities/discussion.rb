# frozen_string_literal: true

module API
  module Entities
    class Discussion < Grape::Entity
      expose :id
      expose :individual_note?, as: :individual_note
      expose :notes, using: Entities::Note
    end
  end
end
