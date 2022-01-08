# frozen_string_literal: true

module API
  module Entities
    class ResourceAccessToken < Entities::PersonalAccessToken
      expose :access_level do |token, options|
        options[:resource].resource_member(token.user).access_level
      end
    end
  end
end
