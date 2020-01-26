# frozen_string_literal: true

module API
  module Entities
    class WikiPageBasic < Grape::Entity
      expose :format
      expose :slug
      expose :title
    end
  end
end
