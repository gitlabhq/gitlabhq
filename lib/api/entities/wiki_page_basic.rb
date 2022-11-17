# frozen_string_literal: true

module API
  module Entities
    class WikiPageBasic < Grape::Entity
      expose :format, documentation: { type: 'string', example: 'markdown' }
      expose :slug, documentation: { type: 'string', example: 'deploy' }
      expose :title, documentation: { type: 'string', example: 'deploy' }
    end
  end
end
