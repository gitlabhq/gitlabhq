# frozen_string_literal: true

module API
  module Entities
    # deprecated old Release representation
    class TagRelease < Grape::Entity
      expose :tag, as: :tag_name
      expose :description
    end
  end
end
