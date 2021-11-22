# frozen_string_literal: true

module API
  module Entities
    class Changelog < Grape::Entity
      expose :to_s, as: :notes
    end
  end
end
