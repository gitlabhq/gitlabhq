# frozen_string_literal: true

module Serverless
  class DomainEntity < Grape::Entity
    expose :id
    expose :domain
  end
end
