# frozen_string_literal: true

module API
  module Entities
    class TreeObject < Grape::Entity
      expose :id, :name, :type, :path

      expose :mode do |obj, options|
        filemode = obj.mode
        filemode = "0" + filemode if filemode.length < 6
        filemode
      end
    end
  end
end
