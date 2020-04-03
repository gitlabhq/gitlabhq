# frozen_string_literal: true

module API
  module Entities
    class X509Issuer < Grape::Entity
      expose :id
      expose :subject
      expose :subject_key_identifier
      expose :crl_url
    end
  end
end
