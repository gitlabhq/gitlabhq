# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessToken < Grape::Entity
      expose :id, :name, :revoked, :created_at, :scopes, :user_id
      expose :active?, as: :active
      expose :expires_at do |personal_access_token|
        personal_access_token.expires_at ? personal_access_token.expires_at.strftime("%Y-%m-%d") : nil
      end
    end
  end
end
