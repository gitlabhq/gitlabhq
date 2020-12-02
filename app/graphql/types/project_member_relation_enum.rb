# frozen_string_literal: true

module Types
  class ProjectMemberRelationEnum < BaseEnum
    graphql_name 'ProjectMemberRelation'
    description 'Project member relation'

    ::MembersFinder::RELATIONS.each do |member_relation|
      value member_relation.to_s.upcase, value: member_relation, description: "#{member_relation.to_s.titleize} members"
    end
  end
end
