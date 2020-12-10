# frozen_string_literal: true

class Vulnerabilities::RequestEntity < Grape::Entity
  expose :headers
  expose :method
  expose :url
  expose :body
end
