# frozen_string_literal: true

module Types
  module Users
    class TypeEnum < BaseEnum
      graphql_name 'UserType'
      description 'Possible types of user'

      User.user_types.each_key do |key|
        value key.to_s.upcase, value: key.to_s, description: key.to_s.humanize.to_s
      end
    end
  end
end
