# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Tag
        attr_accessor :name

        def initialize(name)
          @name = name
        end

        def to_h
          {
            name: name,
            description: description
          }.compact
        end

        def description
          "Operations concerning #{name.humanize}"
        end
      end
    end
  end
end
