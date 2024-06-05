# frozen_string_literal: true

module API
  module Entities
    class ResourceAccessToken < Entities::PersonalAccessToken
      expose :access_level,
        documentation: { type: 'integer',
                         example: 40,
                         description: 'Access level. Valid values are 10 (Guest), 20 (Reporter), 30 (Developer) \
      , 40 (Maintainer), and 50 (Owner). Defaults to 40.',
                         values: [10, 20, 30, 40, 50] } do |token, options|
        options[:resource].member(token.user).access_level
      end
    end
  end
end
