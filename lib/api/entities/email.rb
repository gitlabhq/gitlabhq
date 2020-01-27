# frozen_string_literal: true

module API
  module Entities
    class Email < Grape::Entity
      expose :id, :email
    end
  end
end
