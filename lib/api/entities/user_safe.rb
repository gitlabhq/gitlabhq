# frozen_string_literal: true

module API
  module Entities
    class UserSafe < Grape::Entity
      expose :id, :username
      expose :name do |user|
        user.redacted_name(options[:current_user])
      end
    end
  end
end
