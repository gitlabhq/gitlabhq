# frozen_string_literal: true

module Evidences
  class AuthorEntity < Grape::Entity
    expose :id
    expose :name
    expose :email
  end
end
