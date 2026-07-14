# frozen_string_literal: true

module API
  module Entities
    module Platform
      class Kubernetes < Grape::Entity
        expose :api_url, documentation: { type: 'String' }
        expose :namespace, documentation: { type: 'String' }
        expose :authorization_type, documentation: { type: 'String' }
        expose :ca_cert, documentation: { type: 'String' }
      end
    end
  end
end
