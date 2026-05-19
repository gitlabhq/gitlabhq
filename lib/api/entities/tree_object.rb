# frozen_string_literal: true

module API
  module Entities
    class TreeObject < Grape::Entity
      expose :id, documentation: { type: 'String', example: 'a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba' }
      expose :name, documentation: { type: 'String', example: 'html' }
      expose :type, documentation: { type: 'String', example: 'tree' }
      expose :path, documentation: { type: 'String', example: 'files/html' }

      expose :mode, documentation: { type: 'String', example: '040000' } do |obj, options|
        filemode = obj.mode
        filemode = "0" + filemode if filemode.length < 6
        filemode
      end
    end
  end
end
