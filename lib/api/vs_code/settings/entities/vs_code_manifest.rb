# frozen_string_literal: true

module API
  module VsCode
    module Settings
      module Entities
        class VsCodeManifest < Grape::Entity
          expose :latest
          expose :session, documentation: { type: 'string', example: '1' }
        end
      end
    end
  end
end
