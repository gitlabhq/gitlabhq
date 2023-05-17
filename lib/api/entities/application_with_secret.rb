# frozen_string_literal: true

module API
  module Entities
    # Use with care, this exposes the secret
    class ApplicationWithSecret < Entities::Application
      expose :secret, documentation: {
        type: 'string',
        example: 'ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34'
      } do |application, _options|
        application.plaintext_secret
      end
    end
  end
end
