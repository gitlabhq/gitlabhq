# frozen_string_literal: true

module API
  module Entities
    class TreeObject < Grape::Entity
      expose :id, documentation: { example: 'a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba' }
      expose :name, documentation: { example: 'html' }
      expose :type, documentation: { example: 'tree' }
      expose :path, documentation: { example: 'files/html' }

      expose :mode, documentation: { example: '040000' } do |obj, options|
        filemode = obj.mode
        filemode = "0" + filemode if filemode.length < 6
        filemode
      end
    end
  end
end
