# frozen_string_literal: true

module Types
  class GroupMemberRelationEnum < BaseEnum
    graphql_name 'GroupMemberRelation'
    description 'Group member relation'

    ::GroupMembersFinder::RELATIONS.each do |member_relation|
      value member_relation.to_s.upcase, value: member_relation, description: "#{::GroupMembersFinder::RELATIONS_DESCRIPTIONS[member_relation]}."
    end
  end
end
