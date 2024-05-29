# frozen_string_literal: true

module API
  module Entities
    class Application < Grape::Entity
      expose :id
      expose :uid, as: :application_id,
        documentation: { type: 'string',
                         example: '5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737' }
      expose :name, as: :application_name, documentation: { type: 'string', example: 'MyApplication' }
      expose :redirect_uri, as: :callback_url, documentation: { type: 'string', example: 'https://redirect.uri' }
      expose :confidential, documentation: { type: 'boolean', example: true }
    end
  end
end
