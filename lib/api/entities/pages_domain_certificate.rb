# frozen_string_literal: true

module API
  module Entities
    class PagesDomainCertificate < Grape::Entity
      expose :subject
      expose :expired?, as: :expired
      expose :certificate
      expose :certificate_text
    end
  end
end
