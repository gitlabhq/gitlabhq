# frozen_string_literal: true

class Vulnerabilities::IdentifierEntity < Grape::Entity
  expose :external_type
  expose :external_id
  expose :name
  expose :url
end
