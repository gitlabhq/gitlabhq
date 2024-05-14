# frozen_string_literal: true

module API
  module Entities
    class Invitation < Grape::Entity
      expose :access_level
      expose :created_at
      expose :expires_at
      expose :invite_email
      expose :invite_token
      expose :user_name, if: ->(member, _) { member.user.present? }
      expose :created_by_name
    end
  end
end
