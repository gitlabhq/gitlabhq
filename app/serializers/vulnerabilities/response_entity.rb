# frozen_string_literal: true

class Vulnerabilities::ResponseEntity < Grape::Entity
  expose :headers
  expose :reason_phrase
  expose :status_code
  expose :body
end
