# frozen_string_literal: true

module Types
  class MemberAccessLevelEnum < BaseEnum
    graphql_name 'MemberAccessLevel'
    description 'Access level of a group or project member'

    def self.descriptions
      Gitlab::Access.option_descriptions
    end

    Gitlab::Access.options_with_owner.each do |key, value|
      value key.upcase, value: value, description: descriptions[value]
    end
  end
end

Types::MemberAccessLevelEnum.prepend_mod_with('Types::MemberAccessLevelEnum')
