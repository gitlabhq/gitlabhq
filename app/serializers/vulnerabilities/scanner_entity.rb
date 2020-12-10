# frozen_string_literal: true

class Vulnerabilities::ScannerEntity < Grape::Entity
  expose :external_id
  expose :name
  expose :vendor
end
