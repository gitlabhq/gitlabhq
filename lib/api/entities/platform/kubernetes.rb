# frozen_string_literal: true

module API
  module Entities
    module Platform
      class Kubernetes < Grape::Entity
        expose :api_url
        expose :namespace
        expose :authorization_type
        expose :ca_cert
      end
    end
  end
end
