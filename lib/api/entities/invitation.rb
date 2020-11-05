# frozen_string_literal: true

module API
  module Entities
    class Invitation < Grape::Entity
      expose :access_level
      expose :requested_at
      expose :expires_at
      expose :invite_email
      expose :invite_token
      expose :user_id
    end
  end
end
