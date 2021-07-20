# frozen_string_literal: true

module API
  module Entities
    class ResourceAccessToken < Entities::PersonalAccessToken
      expose :access_level do |token, options|
        options[:project].project_member(token.user).access_level
      end
    end
  end
end
